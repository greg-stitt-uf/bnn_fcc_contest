`timescale 1ns / 1ps

module config_parser #(
    parameter int PW          = 8,
    parameter int MAX_NEURONS = 256,
    parameter int MAX_BEATS   = 98   // ceil(784/PW)
)(
    input  logic        clk,
    input  logic        rst,

    // AXI4-Stream config input (64-bit bus)
    input  logic        cfg_valid,
    output logic        cfg_ready,
    input  logic [63:0] cfg_data,
    input  logic [7:0]  cfg_keep,
    input  logic        cfg_last,

    // bnn_layer config port
    output logic        cfg_we,
    output logic        cfg_tw,
    output logic [7:0]  cfg_nidx,
    output logic [$clog2(MAX_BEATS)-1:0] cfg_addr,
    output logic [PW-1:0]                cfg_wdata,
    output logic [9:0]                   cfg_tdata, 
    input  logic                         cfg_rdy
);

    // ---------------------------------------------------------
    // 1. Asymmetric FIFO (64-bit -> 8-bit)
    // ---------------------------------------------------------
    // Logic to serialize the 64-bit AXI word into bytes
    logic [63:0] fifo_data_q;
    logic [2:0]  fifo_ptr_q;
    logic        fifo_empty;
    logic [7:0]  byte_out;
    logic        byte_valid;
    logic        byte_rd_en;

    assign byte_out   = fifo_data_q[(fifo_ptr_q * 8) +: 8];
    assign byte_valid = !fifo_empty;
    assign cfg_ready  = fifo_empty; // Only accept new 64-bit word when current is exhausted

    always_ff @(posedge clk) begin
        if (rst) begin
            fifo_ptr_q <= 0;
            fifo_empty <= 1'b1;
        end else if (cfg_valid && cfg_ready) begin
            fifo_data_q <= cfg_data;
            fifo_ptr_q  <= 0;
            fifo_empty  <= 1'b0;
        end else if (byte_rd_en && byte_valid) begin
            if (fifo_ptr_q == 3'd7) fifo_empty <= 1'b1;
            else                    fifo_ptr_q <= fifo_ptr_q + 1;
        end
    end

    // ---------------------------------------------------------
    // 2. FSM States
    // ---------------------------------------------------------
    typedef enum logic [2:0] {
        IDLE          = 3'd0,
        RECV_HEADER   = 3'd1,
        DECODE        = 3'd2,
        RECV_W_BYTES  = 3'd3,
        WRITE_W_RAM   = 3'd4,
        RECV_T_BYTES  = 3'd5,
        WRITE_T_RAM   = 3'd6
    } state_t;

    state_t state, next;

    // Header & Internal Registers
    logic [7:0]  hdr_msgtype, hdr_layerid;
    logic [15:0] hdr_layerinputs, hdr_numneurons, hdr_bytesperneu;
    logic [31:0] hdr_totalbytes;
    logic [31:0] thresh_reg;
    
    logic [3:0]  hdr_byte_cnt;
    logic [7:0]  cur_neuron;
    logic [$clog2(MAX_BEATS)-1:0] cur_beat;
    logic [1:0]  thresh_byte_cnt;
    logic [15:0] beats_per_neu;

    // ---------------------------------------------------------
    // 3. FSM Logic
    // ---------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            hdr_byte_cnt <= 0;
            cur_neuron <= 0;
            cur_beat <= 0;
            thresh_byte_cnt <= 0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    hdr_byte_cnt <= 0;
                    cur_neuron <= 0;
                    cur_beat <= 0;
                end

                RECV_HEADER: begin
                    if (byte_valid) begin
                        // Little-Endian Header Unpack (16 Bytes)
                        case (hdr_byte_cnt)
                            0: hdr_msgtype     <= byte_out;
                            1: hdr_layerid     <= byte_out;
                            2: hdr_layerinputs[7:0]  <= byte_out;
                            3: hdr_layerinputs[15:8] <= byte_out;
                            4: hdr_numneurons[7:0]   <= byte_out;
                            5: hdr_numneurons[15:8]  <= byte_out;
                            6: hdr_bytesperneu[7:0]  <= byte_out;
                            7: hdr_bytesperneu[15:8] <= byte_out;
                            8: hdr_totalbytes[7:0]   <= byte_out;
                            9: hdr_totalbytes[15:8]  <= byte_out;
                            10:hdr_totalbytes[23:16] <= byte_out;
                            11:hdr_totalbytes[31:24] <= byte_out;
                        endcase
                        hdr_byte_cnt <= hdr_byte_cnt + 1;
                    end
                end

                DECODE: begin
                    // Pre-compute hardware-friendly limits
                    beats_per_neu <= (hdr_layerinputs + PW - 1) / PW;
                end

                RECV_W_BYTES: begin
                    if (byte_valid) cfg_wdata <= byte_out;
                end

                WRITE_W_RAM: begin
                    if (cfg_rdy) begin
                        if (cur_beat == beats_per_neu - 1) begin
                            cur_beat <= 0;
                            cur_neuron <= cur_neuron + 1;
                        end else begin
                            cur_beat <= cur_beat + 1;
                        end
                    end
                end

                RECV_T_BYTES: begin
                    if (byte_valid) begin
                        thresh_reg <= {byte_out, thresh_reg[31:8]}; // Shift in LE
                        thresh_byte_cnt <= thresh_byte_cnt + 1;
                    end
                end

                WRITE_T_RAM: begin
                    if (cfg_rdy) begin
                        cur_neuron <= cur_neuron + 1;
                        thresh_byte_cnt <= 0;
                    end
                end
            endcase
        end
    end

    // Next State Logic
    always_comb begin
        next = state;
        byte_rd_en = 1'b0;
        cfg_we = 1'b0;
        cfg_tw = 1'b0;
        cfg_nidx = cur_neuron;
        cfg_addr = cur_beat;
        cfg_tdata = thresh_reg[9:0]; // Truncated to COUNT_W=10

        case (state)
            IDLE:        if (byte_valid) next = RECV_HEADER;
            RECV_HEADER: begin
                if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    if (hdr_byte_cnt == 15) next = DECODE;
                end
            end
            DECODE:      next = (hdr_msgtype == 0) ? RECV_W_BYTES : RECV_T_BYTES;
            
            RECV_W_BYTES: begin
                if (byte_valid) next = WRITE_W_RAM;
            end
            
            WRITE_W_RAM: begin
                cfg_we = 1'b1;
                if (cfg_rdy) begin
                    byte_rd_en = 1'b1;
                    if (cur_neuron == hdr_numneurons[7:0] - 1 && cur_beat == beats_per_neu - 1) 
                        next = IDLE;
                    else 
                        next = RECV_W_BYTES;
                end
            end

            RECV_T_BYTES: begin
                if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    if (thresh_byte_cnt == 3) next = WRITE_T_RAM;
                end
            end

            WRITE_T_RAM: begin
                cfg_tw = 1'b1;
                if (cfg_rdy) begin
                    if (cur_neuron == hdr_numneurons[7:0] - 1) next = IDLE;
                    else next = RECV_T_BYTES;
                end
            end
        endcase
    end
endmodule