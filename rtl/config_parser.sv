`timescale 1ns / 1ps

module config_parser #(
    parameter int TARGET_LAYER_ID = 0,
    parameter int INPUTS          = 784,
    parameter int NEURONS         = 256,
    parameter int PW              = 8,

    // Match bnn_layer-style derived parameters
    parameter int COUNT_WIDTH           = $clog2(INPUTS + 1),
    parameter int INPUT_BEATS           = (INPUTS + PW - 1) / PW,
    parameter int CFG_NEURON_WIDTH      = (NEURONS > 1) ? $clog2(NEURONS) : 1,
    parameter int CFG_WEIGHT_ADDR_WIDTH = (INPUT_BEATS > 1) ? $clog2(INPUT_BEATS) : 1
)(
    input  logic                             clk,
    input  logic                             rst,

    // AXI4-Stream config input
    input  logic                             cfg_valid,
    output logic                             cfg_ready,
    input  logic [63:0]                      cfg_data,
    input  logic [7:0]                       cfg_keep,
    input  logic                             cfg_last,

    // Attached bnn_layer config port
    output logic                             cfg_we,
    output logic                             cfg_tw,
    output logic [CFG_NEURON_WIDTH-1:0]      cfg_nidx,
    output logic [CFG_WEIGHT_ADDR_WIDTH-1:0] cfg_addr,
    output logic [PW-1:0]                    cfg_wdata,
    output logic [COUNT_WIDTH-1:0]           cfg_tdata,
    input  logic                             cfg_rdy
);

    typedef enum logic [2:0] {
        IDLE         = 3'd0,
        RECV_HEADER  = 3'd1,
        DECODE       = 3'd2,
        SKIP_PAYLOAD = 3'd3,
        RECV_W_BYTES = 3'd4,
        WRITE_W_RAM  = 3'd5,
        RECV_T_BYTES = 3'd6,
        WRITE_T_RAM  = 3'd7
    } state_t;

    state_t state, next;

    function automatic [5:0] calc_countw(input logic [15:0] n_inputs);
        integer i;
        begin
            calc_countw = 6'd1;
            for (i = 1; i < 32; i = i + 1) begin
                if ((1 << i) >= (n_inputs + 1))
                    calc_countw = i[5:0];
            end
        end
    endfunction

    function automatic [COUNT_WIDTH-1:0] trunc_thresh(
        input logic [31:0] raw,
        input logic [5:0]  cw
    );
        logic [31:0] mask32;
        begin
            if (cw >= 32)
                mask32 = 32'hFFFF_FFFF;
            else
                mask32 = (32'd1 << cw) - 1;

            trunc_thresh = raw[COUNT_WIDTH-1:0] & mask32[COUNT_WIDTH-1:0];
        end
    endfunction

    // ------------------------------------------------------------------
    // 64b -> 8b keep-aware serializer
    // ------------------------------------------------------------------
    logic [63:0] beat_data_q;
    logic [7:0]  beat_keep_q;
    logic [2:0]  beat_ptr_q;
    logic        beat_empty_q;

    logic [7:0]  byte_out;
    logic        byte_valid;
    logic        byte_rd_en;

    assign byte_out   = beat_data_q[beat_ptr_q*8 +: 8];
    assign byte_valid = (!beat_empty_q) && beat_keep_q[beat_ptr_q];

    // Accept next AXI beat only when current beat has been fully drained/skipped
    assign cfg_ready = beat_empty_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            beat_data_q  <= '0;
            beat_keep_q  <= '0;
            beat_ptr_q   <= '0;
            beat_empty_q <= 1'b1;
        end else begin
            if (beat_empty_q) begin
                if (cfg_valid) begin
                    beat_data_q  <= cfg_data;
                    beat_keep_q  <= cfg_keep;
                    beat_ptr_q   <= 3'd0;
                    beat_empty_q <= (cfg_keep == 8'h00);
                end
            end else begin
                if (!beat_keep_q[beat_ptr_q] || byte_rd_en) begin
                    if (beat_ptr_q == 3'd7)
                        beat_empty_q <= 1'b1;
                    else
                        beat_ptr_q <= beat_ptr_q + 3'd1;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Header / payload tracking
    // ------------------------------------------------------------------
    logic [7:0]  hdr_msgtype, hdr_layerid;
    logic [15:0] hdr_layerinputs, hdr_numneurons, hdr_bytesperneu;
    logic [31:0] hdr_totalbytes;

    logic [3:0]  hdr_byte_cnt;
    logic [31:0] payload_bytes_left;

    logic [CFG_NEURON_WIDTH-1:0]      cur_neuron;
    logic [CFG_WEIGHT_ADDR_WIDTH-1:0] cur_beat;
    logic [15:0]                      beats_per_neu_msg;
    logic [5:0]                       msg_countw;
    logic                             target_msg;

    logic [7:0]  weight_byte_q;
    logic [31:0] thresh_reg;
    logic [1:0]  thresh_byte_cnt;

    // ------------------------------------------------------------------
    // DECODE combinational values
    // FIX: use header-derived combinational signals in DECODE next-state,
    // not target_msg/beats/countw regs written in the same cycle.
    // ------------------------------------------------------------------
    logic        dec_target_msg;
    logic [15:0] dec_beats_per_neu;
    logic [5:0]  dec_countw;

    assign dec_target_msg    = (hdr_layerid == TARGET_LAYER_ID[7:0]);
    assign dec_beats_per_neu = (hdr_layerinputs + PW - 1) / PW;
    assign dec_countw        = calc_countw(hdr_layerinputs);

    // ------------------------------------------------------------------
    // Sequential state + datapath
    // ------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            state              <= IDLE;

            hdr_msgtype        <= '0;
            hdr_layerid        <= '0;
            hdr_layerinputs    <= '0;
            hdr_numneurons     <= '0;
            hdr_bytesperneu    <= '0;
            hdr_totalbytes     <= '0;

            hdr_byte_cnt       <= '0;
            payload_bytes_left <= '0;

            cur_neuron         <= '0;
            cur_beat           <= '0;
            beats_per_neu_msg  <= '0;
            msg_countw         <= '0;
            target_msg         <= 1'b0;

            weight_byte_q      <= '0;
            thresh_reg         <= '0;
            thresh_byte_cnt    <= '0;
        end else begin
            state <= next;

            case (state)
                IDLE: begin
                    hdr_byte_cnt       <= '0;
                    payload_bytes_left <= '0;
                    cur_neuron         <= '0;
                    cur_beat           <= '0;
                    thresh_reg         <= '0;
                    thresh_byte_cnt    <= '0;
                end

                RECV_HEADER: begin
                    if (byte_valid && byte_rd_en) begin
                        case (hdr_byte_cnt)
                            4'd0:  hdr_msgtype           <= byte_out;
                            4'd1:  hdr_layerid           <= byte_out;
                            4'd2:  hdr_layerinputs[7:0]  <= byte_out;
                            4'd3:  hdr_layerinputs[15:8] <= byte_out;
                            4'd4:  hdr_numneurons[7:0]   <= byte_out;
                            4'd5:  hdr_numneurons[15:8]  <= byte_out;
                            4'd6:  hdr_bytesperneu[7:0]  <= byte_out;
                            4'd7:  hdr_bytesperneu[15:8] <= byte_out;
                            4'd8:  hdr_totalbytes[7:0]   <= byte_out;
                            4'd9:  hdr_totalbytes[15:8]  <= byte_out;
                            4'd10: hdr_totalbytes[23:16] <= byte_out;
                            4'd11: hdr_totalbytes[31:24] <= byte_out;
                            4'd12: ;
                            4'd13: ;
                            4'd14: ;
                            4'd15: ;
                            default: ;
                        endcase
                        hdr_byte_cnt <= hdr_byte_cnt + 4'd1;
                    end
                end

                DECODE: begin
                    payload_bytes_left <= hdr_totalbytes;
                    beats_per_neu_msg  <= dec_beats_per_neu;
                    msg_countw         <= dec_countw;
                    target_msg         <= dec_target_msg;
                    cur_neuron         <= '0;
                    cur_beat           <= '0;
                    thresh_reg         <= '0;
                    thresh_byte_cnt    <= '0;
                end

                SKIP_PAYLOAD: begin
                    if (byte_valid && byte_rd_en)
                        payload_bytes_left <= payload_bytes_left - 32'd1;
                end

                RECV_W_BYTES: begin
                    if (byte_valid && byte_rd_en) begin
                        weight_byte_q      <= byte_out;
                        payload_bytes_left <= payload_bytes_left - 32'd1;
                    end
                end

                WRITE_W_RAM: begin
                    if (cfg_rdy) begin
                        if (cur_beat == beats_per_neu_msg - 1) begin
                            cur_beat   <= '0;
                            cur_neuron <= cur_neuron + 1'b1;
                        end else begin
                            cur_beat <= cur_beat + 1'b1;
                        end
                    end
                end

                RECV_T_BYTES: begin
                    if (byte_valid && byte_rd_en) begin
                        case (thresh_byte_cnt)
                            2'd0: thresh_reg[7:0]   <= byte_out;
                            2'd1: thresh_reg[15:8]  <= byte_out;
                            2'd2: thresh_reg[23:16] <= byte_out;
                            2'd3: thresh_reg[31:24] <= byte_out;
                        endcase
                        thresh_byte_cnt    <= thresh_byte_cnt + 2'd1;
                        payload_bytes_left <= payload_bytes_left - 32'd1;
                    end
                end

                WRITE_T_RAM: begin
                    if (cfg_rdy) begin
                        cur_neuron      <= cur_neuron + 1'b1;
                        thresh_reg      <= '0;
                        thresh_byte_cnt <= '0;
                    end
                end

                default: ;
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Combinational control
    // ------------------------------------------------------------------
    always_comb begin
        next       = state;
        byte_rd_en = 1'b0;

        cfg_we    = 1'b0;
        cfg_tw    = 1'b0;
        cfg_nidx  = cur_neuron;
        cfg_addr  = cur_beat;
        cfg_wdata = weight_byte_q;
        cfg_tdata = trunc_thresh(thresh_reg, msg_countw);

        case (state)
            IDLE: begin
                if (byte_valid)
                    next = RECV_HEADER;
            end

            RECV_HEADER: begin
                if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    if (hdr_byte_cnt == 4'd15)
                        next = DECODE;
                end
            end

            DECODE: begin
                if (!dec_target_msg)
                    next = SKIP_PAYLOAD;
                else if (hdr_msgtype == 8'd0)
                    next = RECV_W_BYTES;
                else
                    next = RECV_T_BYTES;
            end

            SKIP_PAYLOAD: begin
                if (payload_bytes_left == 0)
                    next = IDLE;
                else if (byte_valid)
                    byte_rd_en = 1'b1;
            end

            RECV_W_BYTES: begin
                if (payload_bytes_left == 0)
                    next = IDLE;
                else if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    next = WRITE_W_RAM;
                end
            end

            WRITE_W_RAM: begin
                cfg_we = 1'b1;
                if (cfg_rdy) begin
                    if (payload_bytes_left == 0)
                        next = IDLE;
                    else
                        next = RECV_W_BYTES;
                end
            end

            RECV_T_BYTES: begin
                if (payload_bytes_left == 0)
                    next = IDLE;
                else if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    if (thresh_byte_cnt == 2'd3)
                        next = WRITE_T_RAM;
                end
            end

            WRITE_T_RAM: begin
                cfg_tw = 1'b1;
                if (cfg_rdy) begin
                    if (payload_bytes_left == 0)
                        next = IDLE;
                    else
                        next = RECV_T_BYTES;
                end
            end

            default: next = IDLE;
        endcase
    end

endmodule