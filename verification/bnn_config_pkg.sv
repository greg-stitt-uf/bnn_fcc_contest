`timescale 1ns / 1ps

package bnn_config_pkg;

    // -------------------------------------------------------------------------
    // Data Structures (Scoreboard Expected Values)
    // -------------------------------------------------------------------------
    
    typedef struct {
        int unsigned neuron;
        int unsigned beat;
        longint unsigned word; // Supports up to PW=64
    } weight_write_t;

    typedef struct {
        int unsigned neuron;
        int unsigned thresh;
    } threshold_write_t;

    // -------------------------------------------------------------------------
    // Config Header Model
    // -------------------------------------------------------------------------
    
    class ConfigHeader;
        bit [7:0]  msg_type;
        bit [7:0]  layer_id;
        bit [15:0] layer_inputs;
        bit [15:0] num_neurons;
        bit [15:0] bytes_per_neuron;
        bit [31:0] total_bytes;

        // Parses the 16-byte raw header array into Little-Endian properties
        function new(byte raw[]);
            this.msg_type         = raw[0];
            this.layer_id         = raw[1];
            this.layer_inputs     = {raw[3],  raw[2]};
            this.num_neurons      = {raw[5],  raw[4]};
            this.bytes_per_neuron = {raw[7],  raw[6]};
            this.total_bytes      = {raw[11], raw[10], raw[9], raw[8]};
            // raw[12:15] are reserved and ignored
        endfunction

    endclass

    // -------------------------------------------------------------------------
    // Config Parser Golden Model
    // -------------------------------------------------------------------------
    
    class ConfigParser;
        int unsigned PW;

        // Associative arrays keyed by layer_id, storing queues of expected writes
        weight_write_t    weight_writes   [int][$];
        threshold_write_t threshold_writes[int][$];
        ConfigHeader      meta            [int];

        function new(int unsigned PW = 8);
            this.PW = PW;
        endfunction

        // Equivalent to math.ceil(math.log2(layer_inputs + 1))
        local function int unsigned count_w(int unsigned layer_inputs);
            if (layer_inputs <= 0) return 1;
            return $clog2(layer_inputs + 1); 
        endfunction

        // Simulates bit-packing weight translation
        local function void parse_weights(byte payload[], ConfigHeader hdr);
            int unsigned N     = hdr.layer_inputs;
            int unsigned BEATS = (N + PW - 1) / PW; // equivalent to math.ceil(N / PW)
            int unsigned bpn   = hdr.bytes_per_neuron;

            for (int unsigned neu = 0; neu < hdr.num_neurons; neu++) begin
                for (int unsigned b = 0; b < BEATS; b++) begin
                    longint unsigned word = 0;
                    
                    for (int unsigned p = 0; p < PW; p++) begin
                        int unsigned idx = b * PW + p;
                        bit wbit;
                        
                        if (idx < N) begin
                            // Extract specific bit from byte payload array
                            wbit = (payload[neu * bpn + (idx / 8)] >> (idx % 8)) & 1;
                        end else begin
                            // Padding rule: must be 1 for BNN layer mapping
                            wbit = 1; 
                        end
                        
                        word |= (longint'(wbit) << p);
                    end
                    
                    weight_writes[hdr.layer_id].push_back('{neu, b, word});
                end
            end
        endfunction

        // Simulates parsing 32-bit thresholds and truncating to COUNT_W
        local function void parse_thresholds(byte payload[], ConfigHeader hdr, int unsigned cw);
            int unsigned mask = (1 << cw) - 1;
            
            for (int unsigned neu = 0; neu < hdr.num_neurons; neu++) begin
                int unsigned raw_thresh;
                // Little-endian unpack 32-bit int from payload byte array
                raw_thresh = {payload[neu * 4 + 3], 
                              payload[neu * 4 + 2], 
                              payload[neu * 4 + 1], 
                              payload[neu * 4 + 0]};
                              
                threshold_writes[hdr.layer_id].push_back('{neu, raw_thresh & mask});
            end
        endfunction

        // Main processing routine (consumes the dynamic queue from the Testbench)
        function void process(ref byte stream[$]);
            int unsigned offset = 0;
            
            // Clear prior state
            weight_writes.delete();
            threshold_writes.delete();
            meta.delete();

            while (offset + 16 <= stream.size()) begin
                byte raw_hdr[];
                ConfigHeader hdr;
                byte payload[];
                
                // Extract 16-byte header
                raw_hdr = new[16];
                for (int i = 0; i < 16; i++) begin
                    raw_hdr[i] = stream[offset + i];
                end
                
                hdr = new(raw_hdr);
                offset += 16;
                
                // Track metadata for the layer
                meta[hdr.layer_id] = hdr;

                // Extract payload bytes based on total_bytes
                payload = new[hdr.total_bytes];
                for (int unsigned i = 0; i < hdr.total_bytes; i++) begin
                    payload[i] = stream[offset + i];
                end
                offset += hdr.total_bytes;

                // Decode payload based on message type
                if (hdr.msg_type == 0) begin
                    parse_weights(payload, hdr);
                end else if (hdr.msg_type == 1) begin
                    int unsigned layer_inputs = 1;
                    int unsigned cw;
                    
                    // Threshold payloads rely on the inputs count from the weight payload
                    if (meta.exists(hdr.layer_id)) begin
                        layer_inputs = meta[hdr.layer_id].layer_inputs;
                    end
                    
                    cw = count_w(layer_inputs);
                    parse_thresholds(payload, hdr, cw);
                end
            end
        endfunction
    endclass

endpackage