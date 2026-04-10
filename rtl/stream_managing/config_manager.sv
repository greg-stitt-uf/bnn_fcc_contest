module config_manager #(
    parameter int BUS_WIDTH = 64
) (
    // general i/o
    input  logic                     clk,
    input  logic                     rst,
    input  logic [BUS_WIDTH-1:0]     config_data_in,
    input  logic                     config_valid,
    input  logic [(BUS_WIDTH/8)-1:0] config_keep,
    input  logic                     config_last,
    output logic                     config_ready,

    // outputs of header
    output logic [7:0]               msg_type,
    output logic [7:0]               layer_id,
    output logic [15:0]              layer_inputs,
    output logic [15:0]              num_neurons,
    output logic [15:0]              bytes_per_neuron,
    output logic [31:0]              total_bytes,
    output logic [31:0]              reserved,
    output logic                     header_valid,

    // outputs of data
    output logic [7:0]               data_out[0:7],
    output logic [7:0]               data_out_valid,
    output logic                     error
);
    localparam int BYTE_LANES = BUS_WIDTH / 8;

    typedef enum logic [1:0] {
        IDLE,
        HEADER,
        PAYLOAD,
        DONE
    } state_t;

    state_t curr_state, next_state;

    // registered data for header fields
    logic [7:0]  msg_type_r, msg_type_r_next;
    logic [7:0]  layer_id_r, layer_id_r_next;
    logic [15:0] layer_inputs_r, layer_inputs_r_next;
    logic [15:0] num_neurons_r, num_neurons_r_next;
    logic [15:0] bytes_per_neuron_r, bytes_per_neuron_r_next;
    logic [31:0] total_bytes_r, total_bytes_r_next;
    logic [31:0] reserved_r, reserved_r_next;
    logic       header_valid_r, header_valid_next;

    // track number of payload bytes received to compare against total_bytes in header
    logic [31:0] payload_bytes_received_r, payload_bytes_received_next;
    logic        error_r, error_next;

    // first 64-bit header beat is captured in IDLE, second is read in HEADER
    logic [BUS_WIDTH-1:0] header_word0_r, header_word0_next;

    // internal signals for shift register
    logic shift_in_ready;
    logic shift_out_ready;
    logic shift_out_valid;
    logic shift_out_last;
    logic [BUS_WIDTH-1:0] shift_out_data;
    logic [(BUS_WIDTH/8)-1:0] shift_out_keep;

    // payload data buffered out of the config stream
    logic [7:0] data_out_r[0:7];
    logic [7:0] data_out_next[0:7];
    logic [7:0] data_out_valid_r;
    logic [7:0] data_out_valid_next;

    // shift register to read in data for header parsing and payload storage
    shift_reg #(
        .WIDTH(BUS_WIDTH),
        .DEPTH(3)
    ) header_shift_reg (
        .clk(clk),
        .rst(rst),
        .shift_in_valid(config_valid),
        .shift_in_keep(config_keep),
        .shift_in_data(config_data_in),
        .shift_in_last(config_last),
        .shift_in_ready(shift_in_ready),
        .shift_out_valid(shift_out_valid),
        .shift_out_data(shift_out_data),
        .shift_out_keep(shift_out_keep),
        .shift_out_last(shift_out_last),
        .shift_out_ready(shift_out_ready)
    );

    assign config_ready = shift_in_ready;
    assign msg_type = msg_type_r;
    assign layer_id = layer_id_r;
    assign layer_inputs = layer_inputs_r;
    assign num_neurons = num_neurons_r;
    assign bytes_per_neuron = bytes_per_neuron_r;
    assign total_bytes = total_bytes_r;
    assign reserved = reserved_r;
    assign header_valid = header_valid_r;
    assign error = error_r;
    assign data_out = data_out_r;
    assign data_out_valid = data_out_valid_r;

    // logic
    always_comb begin
        int unsigned beat_valid_bytes;
        int unsigned payload_total_after_beat;

        beat_valid_bytes = 0;
        payload_total_after_beat = payload_bytes_received_r;
        next_state = curr_state;
        msg_type_r_next = msg_type_r;
        layer_id_r_next = layer_id_r;
        layer_inputs_r_next = layer_inputs_r;
        num_neurons_r_next = num_neurons_r;
        bytes_per_neuron_r_next = bytes_per_neuron_r;
        total_bytes_r_next = total_bytes_r;
        reserved_r_next = reserved_r;
        payload_bytes_received_next = payload_bytes_received_r;
        error_next = error_r;
        header_word0_next = header_word0_r;
        data_out_next = '{default: '0};
        data_out_valid_next = '0;
        shift_out_ready = 1'b0;
        header_valid_next = 1'b0;

        case (curr_state)
            IDLE: begin
                payload_bytes_received_next = '0;
                error_next = 1'b0;
                header_valid_next = 1'b0;

                if (shift_out_valid) begin
                    // read the first beat of the header, then move to next state where second header beat is defined
                    shift_out_ready = 1'b1;
                    header_word0_next = shift_out_data;
                    next_state = HEADER;
                end
            end

            HEADER: begin
                if (shift_out_valid) begin
                    shift_out_ready = 1'b1;
                    header_valid_next = 1'b1;
                    // after reading in second header beat, parse the header and move to payload state
                    // remember, the shift register handles the keep, so we don't need to validate here
                    msg_type_r_next = header_word0_r[7:0];
                    layer_id_r_next = header_word0_r[15:8];
                    layer_inputs_r_next = header_word0_r[31:16];
                    num_neurons_r_next = header_word0_r[47:32];
                    bytes_per_neuron_r_next = header_word0_r[63:48];
                    total_bytes_r_next = shift_out_data[31:0];
                    reserved_r_next = shift_out_data[63:32];

                    if (shift_out_last) begin
                        error_next = 1'b1;
                        next_state = DONE;
                    end else begin
                        payload_bytes_received_next = '0;
                        next_state = PAYLOAD;
                    end
                end
            end

            PAYLOAD: begin
                if (shift_out_valid) begin
                    shift_out_ready = 1'b1;
                    beat_valid_bytes = $countones(shift_out_keep);
                    payload_total_after_beat = payload_bytes_received_r + beat_valid_bytes;
                    payload_bytes_received_next = payload_total_after_beat;

                    // pack the valid bytes into data_out and data_out_valid
                    for (int i = 0; i < BYTE_LANES; i++) begin
                        if (shift_out_keep[i]) begin
                            data_out_next[i] = shift_out_data[i*8 +: 8];
                            data_out_valid_next[i] = 1'b1;
                        end
                    end
                    //$displayformat(-9, 0, " ns");
                    if (shift_out_last) begin // last weight/threshold sent out for this layer
                        if (payload_total_after_beat != total_bytes_r) begin
                            error_next = 1'b1;
                        end // error handle
                        next_state = IDLE; // go back to start
                    end else if (payload_total_after_beat > total_bytes_r) begin
                        error_next = 1'b1;
                        next_state = IDLE;
                    end else if (payload_total_after_beat == total_bytes_r) begin
                        error_next = 1'b1;
                        next_state = IDLE;
                    end
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // state mover and registered stuff
    always_ff @(posedge clk) begin
        if (rst) begin
            curr_state <= IDLE;
            msg_type_r <= '0;
            layer_id_r <= '0;
            layer_inputs_r <= '0;
            num_neurons_r <= '0;
            bytes_per_neuron_r <= '0;
            total_bytes_r <= '0;
            reserved_r <= '0;
            payload_bytes_received_r <= '0;
            error_r <= 1'b0;
            header_word0_r <= '0;
            data_out_r <= '{default: '0};
            data_out_valid_r <= '{default: 1'b0};
            header_valid_r <= 1'b0;
        end else begin
            // had to move this out of comb logic with the help of claude. 
            // i wrote most of this though don't get it twisted
            if (curr_state == PAYLOAD && shift_out_valid && shift_out_ready) begin
                int unsigned beat_valid_bytes_dbg;
                int unsigned payload_total_after_beat_dbg;

                beat_valid_bytes_dbg = $countones(shift_out_keep);
                payload_total_after_beat_dbg = payload_bytes_received_r + beat_valid_bytes_dbg;

                // $display("DBG PAYLOAD time=%0t keep=%b last=%0b bytes_before=%0d beat_valid=%0d bytes_after=%0d total=%0d data=%h",
                //          $time,
                //          shift_out_keep,
                //          shift_out_last,
                //          payload_bytes_received_r,
                //          beat_valid_bytes_dbg,
                //          payload_total_after_beat_dbg,
                //          total_bytes_r,
                //          shift_out_data);

                if (shift_out_last) begin
                    if (payload_total_after_beat_dbg != total_bytes_r) begin
                        $display("Error: Last beat received in PAYLOAD state, but total bytes received (%0d) does not match total_bytes field in header (%0d)",
                                 payload_total_after_beat_dbg,
                                 total_bytes_r);
                    end
                end else if (payload_total_after_beat_dbg > total_bytes_r) begin
                    $display("Error: Total bytes received in PAYLOAD state exceeds total_bytes field in header. Total bytes received: %0d, total_bytes in header: %0d",
                             payload_total_after_beat_dbg,
                             total_bytes_r);
                end else if (payload_total_after_beat_dbg == total_bytes_r) begin
                    $display("Error: Payload byte count reached total_bytes field in header, but TLAST was not asserted. Total bytes received: %0d, total_bytes in header: %0d",
                             payload_total_after_beat_dbg,
                             total_bytes_r);
                end
            end

            curr_state <= next_state;
            msg_type_r <= msg_type_r_next;
            layer_id_r <= layer_id_r_next;
            layer_inputs_r <= layer_inputs_r_next;
            num_neurons_r <= num_neurons_r_next;
            bytes_per_neuron_r <= bytes_per_neuron_r_next;
            total_bytes_r <= total_bytes_r_next;
            reserved_r <= reserved_r_next;
            payload_bytes_received_r <= payload_bytes_received_next;
            error_r <= error_next;
            header_word0_r <= header_word0_next;
            data_out_r <= data_out_next;
            data_out_valid_r <= data_out_valid_next;
            header_valid_r <= header_valid_next;
        end
    end

endmodule


