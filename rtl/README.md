# BNN_FCC Hardware Interface Specification (DUT)

The `bnn_fcc` module is a parameterized, fully-connected binary neural network classifier. It uses AXI4-Stream interfaces for configuration, image inputs, and result outputs.

### Architectural Parameters

| Parameter | Description |
| :--- | :--- |
| `INPUT_DATA_WIDTH` | Bit-width of an individual input element (e.g., 8 for MNIST pixels). |
| `INPUT_BUS_WIDTH`  | Total width of the input AXI-Stream bus. |
| `CONFIG_BUS_WIDTH`  | Width of the configuration/weight bus. |
| `OUTPUT_DATA_WIDTH` | Bit-width of the classification result. |
| `OUTPUT_BUS_WIDTH`  | Total width of the output AXI-Stream bus. |
| `TOTAL_LAYERS`  | Total depth of the topology (Input + Hidden + Output). |
| `TOPOLOGY` | Neurons per layer, with index 0 specifiying # of inputs (e.g., '{784, 256, 256, 10}). |
| `PARALLELIZE_LAYERS`| Enable/disable pipelining between layers (optional). |
| `PARALLEL_NEURONS` | Number of neurons calculated in parallel (optional). |
| `PARALLEL_INPUTS`  | Number of inputs consumed simultaneously per neuron (optional). |
---

Your design most support all parameters except the parallelization configuration options. You can change those however you want to best support your specific architectural strategy. Make sure to change the parameter mapping in the testbench also, which is the only change that is allowed for you submission.

### Interface

#### Global Signals
| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | System Clock. |
| `rst` | Input | 1 | Synchronous Reset (Active High). |

#### AXI4-Stream Configuration Input
Used to load weights and thresholds into the DUT.
| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `config_valid` | Input | 1 | Asserted when `config_data` is valid. |
| `config_ready` | Output | 1 | DUT asserts when ready to accept config data. Clearing applies backpressure. |
| `config_data` | Input | `CONFIG_BUS_WIDTH` | Weight/threshold stream. |
| `config_keep` | Input | `CONFIG_BUS_WIDTH/8` | Specifies individual byte validity of `config_data`. If an individual byte is 0, the DUT should ignore it. |
| `config_last` | Input | 1 | Asserted when receiving the last beat of configuration message. |

#### AXI-Stream Image Input
Used to stream pixel data for classsification.
| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `data_in_valid` | Input | 1 | Asserted when `data_in_data` is valid. |
| `data_in_ready` | Output | 1 | DUT asserts when ready to accept config data. Clearing applies backpressure. |
| `data_in_data` | Input | `INPUT_BUS_WIDTH` | Weight/threshold stream. |
| `data_in_keep` | Input | `INPUT_BUS_WIDTH/8` | Specifies individual byte validity of `data_in_data`. If an individual byte is 0, the DUT should ignore it. |
| `data_in_last` | Input | 1 | Asserted when receiving the last beat of an image stream (i.e., the end of the image).

#### AXI-Stream Classification Output
Outputs the final classification results.
| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `data_out_valid`| Output | 1 | DUT asserts when output is valid |
| `data_out_ready`| Input | 1 | Assserted when downstream logic is ready to accept output. |
| `data_out_data` | Output | `OUTPUT_BUS_WIDTH`| Classified category index. |
| `data_out_keep` | Output | `OUTPUT_BUS_WIDTH/8` | Specifies individual byte validity of `data_out_data`. If an individual byte is 0, the downstream logic will ignore it. |
| `data_out_last` | Output | 1 | Specifies the last beat of an output (should be asserted for every output) |

## Format of Configuration Stream
The configuration stream is formattted to imitate messages received over a network. Each message specifies either the weights or thresholds for a specific layer.

### Configuration Header

The messages starts with the following 128-bit header:

| Bit Field | Name | Width | Description |
| :--- | :--- | :--- | :--- |
| **[7:0]** | `msg_type` | 8 | `0` = Weights, `1` = Thresholds. |
| **[15:8]** | `layer_id` | 8 | Index of the current layer. |
| **[31:16]** | `layer_inputs` | 16 | Exact fan-in (e.g., 784) of `layer_id` (ignore when msg_type=1) |
| **[47:32]** | `num_neurons` | 16 | Total number of neurons in `layer_id`. |
| **[63:48]** | `bytes_per_neuron` | 16 | Number of bytes in the payload per neuron. |
| **[95:64]** | `total_bytes` | 32 | Total payload bytes for the message. |
| **[127:96]** | `reserved` | 32 | Reserved for future use. |

---

Visualization of header for 64-bit configuration bus:

```text
           63          48 47          32 31          16 15     8 7      0
         +--------------+--------------+--------------+--------+--------+
Word 0:  | bytes_per_neu|  num_neurons | layer_inputs | lyr_id | msg_tp |
         +--------------+--------------+--------------+--------+--------+

           127                        96 95                        64
         +------------------------------+-------------------------------+
Word 1:  |           reserved           |          total_bytes          |
         +------------------------------+-------------------------------+
```

### Configuration Payload

Following the payload is a series of `total_bytes` bytes, as specified in the
header. For weights (msg_type=0), the payload packs the individual weights for 
each neuron into bytes. For example, weight 0 of neuron 0 is stored in bit 0 of
byte 0 of the payload. Weight 7 of neuron 0 is stored in bit 7 of byte 0. Weight 8
of neuron 0 is stored in bit 0 of byte 1, etc.

The payload always byte aligns the weights for a given neuron. So, if a neuron has 13
inputs/weights, the payload will pad the 13 weights with three 1s to avoid starting the
next neuron on a non-byte boundary. The padding uses 1s instead of 0s due to the math
of BNNs. By padding the image with 0s and the weights with 1s, the unused bits have no
affect on the neuron output.

Note that it is likely for the payload to not align with the configuration bus width.
For example, for a 64-bit bus, the payload would have to consist of a multiple of 8 bytes.
If the payload is not aligned with the bus width, the design should rely on either an
internal counter, and/or the TKEEP signal from AXI streaming, which will flag the validity
of each byte.

For thresholds (msg_type=1), the payload provides a single 32-bit threshold for each neuron.

The AXI TLAST signal is used to flag the beat that contains the last data for the message.

### Format of Image Stream

The image is provided to the module as a stream of INPUT_DATA_WIDTH-bit pixels, where each beat
on the data_in bus provides INPUT_DATA_WIDTH / INPUT_BUS_WIDTH pixels. In the case of image sizes
that don't align with INPUT_BUS_WIDTH, the source provides the AXI TKEEP signal to flag the validity
of pixels. For example, a 9 pixel image (72 total bits) on a 64-bit bus would require two beats. The
first beat would have TKEEP=1 for all 8 bytes. The second beat would have TKEEP=1 for the first byte
and TKEEP=0 for the next 7 bytes.

The AXI TLAST signal is used to flag the beat that contains the last pixel of the image.

### Format of Output Stream

The output stream specifies the category for each input image. To be consistent with the TLAST usage 
in the input stream, your design should assert data_out_last for every output, unless using a custom
topology that provides more than 256 categories. You should also set data_out_keep according to AXI
TKEEP semantics since the output is unlikely to use all bytes on the output bus.


## Usage

The user of bnn_fcc must first provide the "model" (weights and thresholds) on the configuation bus
before streaming any image inputs. The testbench imitates this procedure. You do not need to include
error checking for image data that arrives before configuration, but it would be a good practice.

After the configuration is performed, your module is assumed to be in full streaming mode where an
upstream source can provide an arbitrary number of images at any rate. You can assume the images are
sized according to the configured topology. Adding a panic signal for a mismatch would be a good
practice, but is not a design requirement.

You can assume that the module must be reset before a new configuration.


