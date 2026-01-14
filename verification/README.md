# Binary Neural Net (BNN) Fully Connected Classifier (FCC) Testbench (bnn_fcc_tb)

This folders contains a parameterized SystemVerilog testbench for verifying the fully connected binary neural network classifier. It supports both a fixed SFC topology (784-256-256-10) for MNIST digit recognition and user-defined custom topologies.

## Features
* **Dual Mode Operation**: Toggle between trained MNIST weights or randomized models for architectural exploration.
* **AXI4-Stream Integration**: Fully compliant handshaking with configurable bus widths and randomized back-pressure/validity.
* **Automated Reference Model**: Includes a SystemVerilog-based reference model to verify hardware outputs against expected Python-generated results.
* **Parameterized Parallelism**: Configurable neuron and input parallelism to match your specific DUT implementation.

---

## Getting Started

### 1. Prerequisites
* **Simulator**: Siemens Questa/ModelSim (recommended) or any IEEE 1800-2012 compliant simulator.
* **Data Files**: Ensure the Python training data and test vectors are located in the directory specified by `BASE_DIR`.


### 3. Running the Simulation (WORK IN PROGRESS)
1. Open your simulator and navigate to the `sim/` directory.
2. Compile the package, DUT, and testbench:
```tcl
vlog -sv ../rtl/bnn_fcc.sv
vlog -sv ../verification/bnn_fcc_tb_pkg.sv
vlog -sv ../verification/bnn_fcc_tb.sv
```
3. Initialize and run the simulation:
```tcl
vsim -gBASE_DIR="../python" -gNUM_TEST_IMAGES=100 -gDATA_IN_VALID_PROBABILITY=0.8 work.bnn_fcc_tb
run -all
```

---

## Testbench Parameters (WORK IN PROGRESS)

The testbench is highly configurable via SystemVerilog parameters. Below are the most critical:

### Configuration & Topology
| Parameter | Default | Description |
| :--- | :--- | :--- |
| `USE_CUSTOM_TOPOLOGY` | `0` | `0`: Use MNIST SFC. `1`: Use `CUSTOM_TOPOLOGY` array. |
| `NUM_TEST_IMAGES` | `10` | Total images to stream during simulation. |
| `BASE_DIR` | `"../python"`| Path to weights/vectors relative to simulator working dir. |

### Bus & Data Settings
| Parameter | Default | Description |
| :--- | :--- | :--- |
| `CONFIG_BUS_WIDTH` | `64` | Bit-width for the AXI-Stream configuration bus. |
| `INPUT_BUS_WIDTH` | `64` | Bit-width for the input pixel stream. |
| `INPUT_DATA_WIDTH` | `8` | **Fixed at 8**. Bit-width of individual pixels. |

### Stress Testing (Contest Requirements)
To fully verify your design's robustness against back-pressure, set these values in the `vsim` command:
* `TOGGLE_DATA_OUT_READY = 1`
* `CONFIG_VALID_PROBABILITY = 0.8`
* `DATA_IN_VALID_PROBABILITY = 0.8`

---

## Known Limitations
* `INPUT_DATA_WIDTH` must be exactly `8`. Sub-byte packing or multi-byte element alignment is not currently implemented in the driver loop.
* `TIMEOUT` is set to `10ms` by default. For very large simulations or slow topologies, increase this parameter to avoid premature termination.
* `BASE_DIR` must be passed as a generic during `vsim` if the simulation is not run from the repository root.