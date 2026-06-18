# Multi-Fidelity Bayesian Optimization for PHITS

This repository provides an automated Bayesian Optimization (BO) pipeline designed to optimize target thickness in PHITS (Particle and Heavy Ion Transport code System) simulations. The goal is to maximize particle flux while efficiently managing computational resources.

## Overview

The core logic is driven by a Python-based optimizer (`Optim_BO.py`). It uses a Gaussian Process (GP) surrogate model to approximate the simulation results and an Expected Improvement (EI) acquisition function to sequentially select the best target thickness to evaluate next.

## Key Features (Python Optimizer)

* **Multi-Fidelity Approach:** The script dynamically chooses between `low` and `high` fidelity simulation modes. It evaluates the utility-to-cost ratio, allowing it to explore the parameter space cheaply and only run expensive, high-accuracy simulations when it is mathematically justified.
* **Gaussian Process Regression:** Handles noisy simulation outputs, calculating mean predictions and plotting uncertainty bounds across the target thickness domain.
* **State Persistence (Auto-Restart):** The script automatically reads `output.txt` upon startup. If a run is interrupted, it will seamlessly resume from the last evaluated point without wasting computation time.
* **Automated Visualization:** At every iteration, it generates and saves plots in the `./graphs/` directory. These graphs visualize the current GP model, uncertainty areas, and the state of the acquisition function.

## Prerequisites

* Python 3.x
* Required Python packages: `numpy`, `scipy`, `matplotlib`
* PHITS executable (`phits_LinGfort_OMP`) available in your environment.

## Usage

1. Ensure your Bash wrapper script is named `run1D.sh` (or update the filename directly in the Python script) and that it accepts two arguments: `[thickness]` and `[fidelity]`.
2. Start the optimization process:
   ```bash
   python Optim_BO.py
