# BNN_FCC Hardware Design Contest

This repository provides a top-level interface and testing framework for a binary neural network (BNN). Specifically, the module implements a fully connected classifier (FCC).

In this contest, you will be implementing the provided top-level [bnn_fcc](rtl/bnn_fcc.sv) module, optimizing it for a specific use case, and ensuring it passes a variety of tests by 
simulating it with a provided testbench. You will then evaluate the latency, throughput, clock frequency, and resource utilization for your design.

The contest represents a collaboration between Apple, Greg Stitt, and EEL6935 Reconfigurable Computing 2 at University of Florida. Apple will be providing prizes for the top submissions.

## Overview

This section provides an overview of the required functionality. See [rtl/README.md](rtl/README.md) for a detailed description of the bnn_fcc interface. See [verification/README.md](verification/README.md) for a detailed description of the testbench and how to simulate your design. For more background information on BNNs, see the [included slides](TBD).

The bnn_fcc module takes an image input, consisting of 8-bit pixels, and classifies that image into one of multiple possible categories. The module is parameterized to support
any BNN topology, but the contest will be judged based on the small, fully connected (SFC) topology from the following FINN paper:

> Umuroglu, Y., Fraser, N. J., Gambardella, G., Blott, M., Leong, P., Jahre, M., & Vissers, K. (2017). FINN: A Framework for Fast, Scalable Binarized Neural Network Inference. In Proceedings of the 2017 ACM/SIGDA International Symposium on Field-Programmable Gate Arrays (pp. 65-74). DOI: 10.1145/3020078.3021744

The SFC topology is referred to as 784->256->256->10, which means 784 8-bit inputs, one hidden layer with 256 neurons, a second hidden layer with 256 neurons, and an output layer with 10 neurons. The repository provides a model (weights and thresholds) for the SFC topology, which was trained from the [MNIST](https://www.tensorflow.org/datasets/catalog/mnist) dataset for 0-9 digit recognition. Each of the 10 neurons in the output layer corresponds to a single category.

The bnn_fcc module has three different interfaces: configuration, data input, and data output. All three interfaces use the [AXI4-Stream protocol](https://developer.arm.com/documentation/ihi0051/a/).

The configuration interface receives a stream of data that contains the "model" of the network. For a BNN, this model specifies weights and thresholds for every neuron in every layer of the BNN. The exact format of the configuration stream is specified [here](TBD). Your design must initially parse this configuration stream and configure your own custom on-chip memory hierarchy to feed weights and thresholds to your neuron processing units. This "data movement" is surprisingly challenging and will likely be the most time consuming part of the project.

The data input stream provides 8-bit pixels from an image. The bnn_fcc module then uses the provided model (weights and thresholds) to classify that image into a specific category.

The data output stream provides the classified result for the provided input image. 

Note that both the configuration stream and data input stream leverage the TKEEP functionality from the AXI4-Stream protocol. AXI4 streaming requires the bus width to be byte aligned (i.e., a multiple of 8 bits). For specific bus widths, some of those bytes might be unused. For example, assume we have a 64-bit bus (8 bytes), and receive an image with 9 8-bit pixels. The initial "beat" on the bus would contain 8 valid bytes. However, the second beat would contain only one valid byte. While the bnn_fcc module could potentially leverage knowledge of the image size to ignore the unused bytes, AXI streaming also provides the TKEEP signal to flag the validity of each byte. For this example, the second beat would assert TKEEP for the first byte, and clear it for the other 7 bytes.

Similarly, all interfaces leverage TLAST, which specifies the last beat in a stream. For the configuration stream, TLAST specifies the end of a configuration message. For the image input, TLAST specifies the end of the image. For the output interface, TLAST should always be asserted since the size of an output "packet" is always one beat (unless you modify the parameters to support > 256 categories).

Since a BNN can only process individual bits, the 8-bit pixels must initially be "binarized." To match the functionality of the testbench, this binarization should be done by comparing the 8-bit pixel value with 128. If the value is >= 128, the 8-bit pixel is replaced by a 1. Otherwise, it is replaced by a 0.

Neurons in hidden layers always output a 0 or 1. However, the output layer is handled differently. Output layer neurons output their multi-bit "population count", which represents the strength of the classification for that neuron, where each neuron represents one classification category. The BNN then applies an "argmax" across those population counts, which simply assigns the BNN output with the index of the the neuron (i.e., the classified category) that had the largest population count.

## Project Objective
The finish the project, you must complete the following:
* Simulate your design using the provided testbench with no failing tests.
* Synthesize your design for a TBD FPGA, measure maximum clock frequency, and collect resource utilization results.
* Measure cycle latency and throughput using the provided testbench.
* Include a report that describes your targeted use case (e.g., minimize latency given a throughput constraint) and presents your results.

## Judging Criteria
Submissions will be judged based on:
* Quality of optimization for the chosen use case.
* Quality of overall verification (unit testing of individual modules, functional coverage, etc.)
* Quality of code (readability, paramterization, )

## Languages, Tools, FPGA
* **HDL:** SystemVerilog (IEEE 1800-2012)
* **Simulator:** Siemens Questa/ModelSim or IEEE 1800-2012 compliant simulator
* **Synthesis:** Xilinx Vivado (any recent version)
* **FPGA:** Xilinx Ultrascale+ TBD

## Directory Structure
```text
.
├── rtl/                 # Hardware Source Files
|   ├── bnn_fcc.sv       # Top-level DUT (complete this file)
|   └── your own files
├── verification/        # Testbench files
|   ├── bnn_fcc_tb.sv
|   ├── bnn_fcc_tb_pkg.sv
|   └── your own files
├── slides/              # Slides explaning the project
|   └── TBD
├── sim/                 # Recommended location for simulator project
└── python/              # Python training scripts, reference model, training data, and test vectors
    ├── training_data/   # Weights and Thresholds
    └── test_vectors/
```

# Git Instructions for How to Participate (Forking & Syncing Guide)

Use this guide to set up your design environment and keep your local files updated if the contest organizers release template updates.

---

## 1. Fork the Original Repository

You initially want your own copy of the contest repository that you can change. Git makes this posssible via a "fork."

### Option A: Standard UI Fork
Click the **Fork** button at the top-right of the contest repository. This creates a copy under your own account where you can safely upload your designs.

### Option B: Manual Mirroring
If you need to move the files to a different platform (e.g., from GitHub to a private GitLab):
1. Create a new, empty repository on your account.
2. Clone the original as a bare mirror:
   `git clone --mirror https://github.com/CONTEST_HOLDER/template-repo.git`
3. Push to your new repository:
   `cd template-repo.git`
   `git push --mirror https://github.com/YOUR_USERNAME/your-design-repo.git`

---

## 2. Local Setup
Once you have your fork, clone it and link it back to the original source to receive updates.

1. **Clone your fork:**
   `git clone https://github.com/YOUR_USERNAME/your-design-repo.git`
2. **Add the contest source as 'upstream':**
   `git remote add upstream https://github.com/CONTEST_HOLDER/template-repo.git`

---

## 3. Pulling Updates from Organizers
If the contest organizers update the template or assets, run these commands to sync your work:

1. `git fetch upstream`
2. `git checkout main`
3. `git merge upstream/main`
4. `git push origin main`

---

## 4. Resolving Conflicts
If you edited a file that the organizers also updated, Git will ask you to choose which version to keep during the merging process.

1. Open the conflicted file.
2. You will see markers:
   `<<<<<<< HEAD` (Your Design)
   `=======`
   `>>>>>>> upstream/main` (Organizer Update)
3. Delete the markers and keep the parts of the code/design you want. For the contest, you must keep the changes from the organizers.
4. Finalize the fix:
   `git add <filename>`
   `git commit -m "Merged updates from contest source"`
5. Run `git status`. It should no longer say "You have unmerged paths."
6. Your local merge isn't on GitHub until you push:
   `git push origin main`

---

## Quick Command Table

| Task | Command |
| :--- | :--- |
| **Link Original** | `git remote add upstream <url>` |
| **Download Updates** | `git fetch upstream` |
| **Apply Updates** | `git merge upstream/main` |
| **Update Your Fork** | `git push origin main` |

# Submission Instructions
Instructions for submitting the repository with your design will be explained in EEL6935 Reconfigurable Computing 2.