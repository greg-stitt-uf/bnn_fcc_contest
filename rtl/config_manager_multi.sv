`default_nettype none

module config_manager_multi #(
    parameter int CONFIG_BUS_WIDTH = 64,
    parameter int PW               = 8,

    parameter int L0_INPUTS        = 784,
    parameter int L0_NEURONS       = 256,
    parameter int L0_COUNT_WIDTH   = $clog2(L0_INPUTS + 1),
    parameter int L0_INPUT_BEATS   = (L0_INPUTS + PW - 1) / PW,
    parameter int L0_NIDX_W        = (L0_NEURONS > 1) ? $clog2(L0_NEURONS) : 1,
    parameter int L0_ADDR_W        = (L0_INPUT_BEATS > 1) ? $clog2(L0_INPUT_BEATS) : 1,

    parameter int L1_INPUTS        = 256,
    parameter int L1_NEURONS       = 256,
    parameter int L1_COUNT_WIDTH   = $clog2(L1_INPUTS + 1),
    parameter int L1_INPUT_BEATS   = (L1_INPUTS + PW - 1) / PW,
    parameter int L1_NIDX_W        = (L1_NEURONS > 1) ? $clog2(L1_NEURONS) : 1,
    parameter int L1_ADDR_W        = (L1_INPUT_BEATS > 1) ? $clog2(L1_INPUT_BEATS) : 1,

    parameter int L2_INPUTS        = 256,
    parameter int L2_NEURONS       = 10,
    parameter int L2_COUNT_WIDTH   = $clog2(L2_INPUTS + 1),
    parameter int L2_INPUT_BEATS   = (L2_INPUTS + PW - 1) / PW,
    parameter int L2_NIDX_W        = (L2_NEURONS > 1) ? $clog2(L2_NEURONS) : 1,
    parameter int L2_ADDR_W        = (L2_INPUT_BEATS > 1) ? $clog2(L2_INPUT_BEATS) : 1,

    localparam int MAX_NEURONS =
        (L0_NEURONS >= L1_NEURONS) ?
            ((L0_NEURONS >= L2_NEURONS) ? L0_NEURONS : L2_NEURONS) :
            ((L1_NEURONS >= L2_NEURONS) ? L1_NEURONS : L2_NEURONS),

    localparam int MAX_BEATS =
        (L0_INPUT_BEATS >= L1_INPUT_BEATS) ?
            ((L0_INPUT_BEATS >= L2_INPUT_BEATS) ? L0_INPUT_BEATS : L2_INPUT_BEATS) :
            ((L1_INPUT_BEATS >= L2_INPUT_BEATS) ? L1_INPUT_BEATS : L2_INPUT_BEATS),

    localparam int CFG_NEURON_W = (MAX_NEURONS > 1) ? $clog2(MAX_NEURONS) : 1,
    localparam int CFG_WEIGHT_ADDR_W = (MAX_BEATS > 1) ? $clog2(MAX_BEATS) : 1,
    localparam int THRESHOLD_W =
        (L0_COUNT_WIDTH > L1_COUNT_WIDTH) ?
            ((L0_COUNT_WIDTH > L2_COUNT_WIDTH) ? L0_COUNT_WIDTH : L2_COUNT_WIDTH) :
            ((L1_COUNT_WIDTH > L2_COUNT_WIDTH) ? L1_COUNT_WIDTH : L2_COUNT_WIDTH)
) (
    input  wire logic                          clk,
    input  wire logic                          rst,

    input  wire logic                          cfg_valid,
    output      logic                          cfg_ready,
    input  wire logic [CONFIG_BUS_WIDTH-1:0]   cfg_data,
    input  wire logic [CONFIG_BUS_WIDTH/8-1:0] cfg_keep,
    input  wire logic                          cfg_last,

    output      logic                          out_cfg_write_en,
    output      logic [1:0]                    out_cfg_layer_sel,
    output      logic [CFG_NEURON_W-1:0]       out_cfg_neuron_idx,
    output      logic [CFG_WEIGHT_ADDR_W-1:0]  out_cfg_weight_addr,
    output      logic [PW-1:0]                 out_cfg_weight_data,
    output      logic [THRESHOLD_W-1:0]        out_cfg_threshold_data,
    output      logic                          out_cfg_threshold_write,
    input  wire logic                          out_cfg_ready
);

    localparam int CFG_KEEP_W = CONFIG_BUS_WIDTH / 8;
    localparam int BEAT_PTR_W = (CFG_KEEP_W > 1) ? $clog2(CFG_KEEP_W) : 1;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_RECV_HEADER,
        ST_DECODE,
        ST_SKIP_PAYLOAD,
        ST_RECV_W_BYTE,
        ST_WRITE_W,
        ST_RECV_T_BYTES,
        ST_WRITE_T
    } state_t;

    state_t state, next;

    logic [CONFIG_BUS_WIDTH-1:0] beat_data_q;
    logic [CFG_KEEP_W-1:0]       beat_keep_q;
    logic [BEAT_PTR_W-1:0]       beat_ptr_q;
    logic                        beat_empty_q;

    logic [7:0]  byte_out;
    logic        byte_valid;
    logic        byte_rd_en;

    logic [7:0]  hdr_msgtype, hdr_layerid;
    logic [15:0] hdr_layerinputs, hdr_numneurons, hdr_bytesperneu;
    logic [31:0] hdr_totalbytes;
    logic [3:0]  hdr_byte_cnt;

    logic [31:0] payload_bytes_left;
    logic [1:0]  active_layer_sel;
    logic [15:0] active_beats_per_neu;
    logic [5:0]  active_countw;
    logic        active_layer_valid;

    logic [CFG_NEURON_W-1:0]      cur_neuron;
    logic [CFG_WEIGHT_ADDR_W-1:0] cur_beat;

    logic [7:0]  weight_byte_q;
    logic [31:0] thresh_reg;
    logic [1:0]  thresh_byte_cnt;

    logic [31:0] trunc_mask;
    logic [31:0] trunc_thresh;

    initial begin
        assert ((CONFIG_BUS_WIDTH % 8) == 0)
        else $fatal(1, "CONFIG_BUS_WIDTH must be a multiple of 8");
    end

    assign byte_out   = beat_data_q[8*beat_ptr_q +: 8];
    assign byte_valid = (!beat_empty_q) && beat_keep_q[beat_ptr_q];
    assign cfg_ready  = beat_empty_q;

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
                    beat_ptr_q   <= '0;
                    beat_empty_q <= (cfg_keep == '0);
                end
            end else begin
                if (!beat_keep_q[beat_ptr_q] || byte_rd_en) begin
                    if (beat_ptr_q == CFG_KEEP_W-1)
                        beat_empty_q <= 1'b1;
                    else
                        beat_ptr_q <= beat_ptr_q + 1'b1;
                end
            end
        end
    end

    always_comb begin
        active_layer_valid = 1'b0;
        active_beats_per_neu = 16'd0;
        active_countw = 6'd1;

        case (hdr_layerid)
            8'd0: begin
                active_layer_valid   = 1'b1;
                active_beats_per_neu = L0_INPUT_BEATS[15:0];
                active_countw        = L0_COUNT_WIDTH[5:0];
            end
            8'd1: begin
                active_layer_valid   = 1'b1;
                active_beats_per_neu = L1_INPUT_BEATS[15:0];
                active_countw        = L1_COUNT_WIDTH[5:0];
            end
            8'd2: begin
                active_layer_valid   = 1'b1;
                active_beats_per_neu = L2_INPUT_BEATS[15:0];
                active_countw        = L2_COUNT_WIDTH[5:0];
            end
            default: begin
                active_layer_valid   = 1'b0;
                active_beats_per_neu = 16'd0;
                active_countw        = 6'd1;
            end
        endcase
    end

    always_comb begin
        if (active_countw >= 32)
            trunc_mask = 32'hFFFF_FFFF;
        else
            trunc_mask = (32'h0000_0001 << active_countw) - 1;

        trunc_thresh = thresh_reg & trunc_mask;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state              <= ST_IDLE;
            hdr_msgtype        <= '0;
            hdr_layerid        <= '0;
            hdr_layerinputs    <= '0;
            hdr_numneurons     <= '0;
            hdr_bytesperneu    <= '0;
            hdr_totalbytes     <= '0;
            hdr_byte_cnt       <= '0;
            payload_bytes_left <= '0;
            active_layer_sel   <= '0;
            cur_neuron         <= '0;
            cur_beat           <= '0;
            weight_byte_q      <= '0;
            thresh_reg         <= '0;
            thresh_byte_cnt    <= '0;
        end else begin
            state <= next;

            case (state)
                ST_IDLE: begin
                    hdr_byte_cnt       <= '0;
                    payload_bytes_left <= '0;
                    cur_neuron         <= '0;
                    cur_beat           <= '0;
                    thresh_reg         <= '0;
                    thresh_byte_cnt    <= '0;
                end

                ST_RECV_HEADER: begin
                    if (byte_valid && byte_rd_en) begin
                        case (hdr_byte_cnt)
                            4'd0:  hdr_msgtype            <= byte_out;
                            4'd1:  hdr_layerid            <= byte_out;
                            4'd2:  hdr_layerinputs[7:0]   <= byte_out;
                            4'd3:  hdr_layerinputs[15:8]  <= byte_out;
                            4'd4:  hdr_numneurons[7:0]    <= byte_out;
                            4'd5:  hdr_numneurons[15:8]   <= byte_out;
                            4'd6:  hdr_bytesperneu[7:0]   <= byte_out;
                            4'd7:  hdr_bytesperneu[15:8]  <= byte_out;
                            4'd8:  hdr_totalbytes[7:0]    <= byte_out;
                            4'd9:  hdr_totalbytes[15:8]   <= byte_out;
                            4'd10: hdr_totalbytes[23:16]  <= byte_out;
                            4'd11: hdr_totalbytes[31:24]  <= byte_out;
                            default: ;
                        endcase
                        hdr_byte_cnt <= hdr_byte_cnt + 4'd1;
                    end
                end

                ST_DECODE: begin
                    payload_bytes_left <= hdr_totalbytes;
                    active_layer_sel   <= hdr_layerid[1:0];
                    cur_neuron         <= '0;
                    cur_beat           <= '0;
                    thresh_reg         <= '0;
                    thresh_byte_cnt    <= '0;
                end

                ST_SKIP_PAYLOAD: begin
                    if (byte_valid && byte_rd_en)
                        payload_bytes_left <= payload_bytes_left - 32'd1;
                end

                ST_RECV_W_BYTE: begin
                    if (byte_valid && byte_rd_en) begin
                        weight_byte_q      <= byte_out;
                        payload_bytes_left <= payload_bytes_left - 32'd1;
                    end
                end

                ST_WRITE_W: begin
                    if (out_cfg_ready) begin
                        if (cur_beat == active_beats_per_neu - 1) begin
                            cur_beat   <= '0;
                            cur_neuron <= cur_neuron + 1'b1;
                        end else begin
                            cur_beat <= cur_beat + 1'b1;
                        end
                    end
                end

                ST_RECV_T_BYTES: begin
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

                ST_WRITE_T: begin
                    if (out_cfg_ready) begin
                        cur_neuron      <= cur_neuron + 1'b1;
                        thresh_reg      <= '0;
                        thresh_byte_cnt <= '0;
                    end
                end

                default: ;
            endcase
        end
    end

    always_comb begin
        next = state;
        byte_rd_en = 1'b0;

        out_cfg_write_en        = 1'b0;
        out_cfg_layer_sel       = active_layer_sel;
        out_cfg_neuron_idx      = cur_neuron;
        out_cfg_weight_addr     = cur_beat;
        out_cfg_weight_data     = weight_byte_q[PW-1:0];
        out_cfg_threshold_data  = trunc_thresh[THRESHOLD_W-1:0];
        out_cfg_threshold_write = 1'b0;

        case (state)
            ST_IDLE: begin
                if (byte_valid)
                    next = ST_RECV_HEADER;
            end

            ST_RECV_HEADER: begin
                if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    if (hdr_byte_cnt == 4'd15)
                        next = ST_DECODE;
                end
            end

            ST_DECODE: begin
                if (!active_layer_valid)
                    next = ST_SKIP_PAYLOAD;
                else if (hdr_msgtype == 8'd0)
                    next = ST_RECV_W_BYTE;
                else
                    next = ST_RECV_T_BYTES;
            end

            ST_SKIP_PAYLOAD: begin
                if (payload_bytes_left == 0)
                    next = ST_IDLE;
                else if (byte_valid)
                    byte_rd_en = 1'b1;
            end

            ST_RECV_W_BYTE: begin
                if (payload_bytes_left == 0)
                    next = ST_IDLE;
                else if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    next = ST_WRITE_W;
                end
            end

            ST_WRITE_W: begin
                out_cfg_write_en = active_layer_valid;
                if (out_cfg_ready) begin
                    if (payload_bytes_left == 0)
                        next = ST_IDLE;
                    else
                        next = ST_RECV_W_BYTE;
                end
            end

            ST_RECV_T_BYTES: begin
                if (payload_bytes_left == 0)
                    next = ST_IDLE;
                else if (byte_valid) begin
                    byte_rd_en = 1'b1;
                    if (thresh_byte_cnt == 2'd3)
                        next = ST_WRITE_T;
                end
            end

            ST_WRITE_T: begin
                out_cfg_threshold_write = active_layer_valid;
                if (out_cfg_ready) begin
                    if (payload_bytes_left == 0)
                        next = ST_IDLE;
                    else
                        next = ST_RECV_T_BYTES;
                end
            end

            default: next = ST_IDLE;
        endcase
    end

endmodule

`default_nettype wire