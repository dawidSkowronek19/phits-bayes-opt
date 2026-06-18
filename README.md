# Multi-Fidelity Bayesian Optimization for PHITS

This repository provides a Python-based framework for optimizing target thickness in Monte Carlo simulations using the PHITS (Particle and Heavy Ion Transport code System) code. The system employs Bayesian Optimization coupled with a Multi-Fidelity approach to minimize computational overhead in high-energy physics simulations.

## Core Capabilities

* **Multi-Fidelity Strategy:** Dynamically selects simulation fidelity (particle count) based on the predicted relative error derived from the Gaussian Process variance. If the predicted uncertainty exceeds 1.5%, a low-fidelity simulation is executed. Otherwise, a high-fidelity simulation is triggered for precise exploitation.
* **Kernel Specification:** Utilizes the Matérn 5/2 kernel, which is mathematically suited for modeling non-linear physical responses and local discontinuities in particle transport.
* **Acquisition Function:** Implements Expected Improvement (EI) to balance exploration of the parameter space with the exploitation of known optimal regions.
* **Automated Execution & Parsing:** Interfaces with PHITS via a bash wrapper (`run1D.sh`), autonomously executing the simulation, waiting for completion, and parsing the standard output files to extract particle flux and statistical errors.
* **Headless Server Support:** Implements the `Agg` backend in `matplotlib` for generating optimization graphs on headless Linux compute nodes without an X11 display.

## Prerequisites

* **Python 3.x**
* Required packages: `numpy`, `scipy`, `matplotlib`
* **PHITS** simulation environment installed and configured in the system path.
* Linux environment.

## Usage

1. **Permissions:** Ensure the bash wrapper script is executable.
   ```bash
   chmod +x run1D.sh
