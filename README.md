# WDS Optimizer - Water Distribution System Optimization Toolkit

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021b%2B-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-1.0.0--alpha-green.svg)]()

**WDS Optimizer** is an open-source MATLAB-based graphical environment designed for optimizing pipe diameters in Water Distribution Systems (WDS). Built directly on top of the **EPANET C-Toolkit (v2.3)**, it combines robust hydraulic simulations with metaheuristic optimization strategies.

Version 1.0.0 features an integer-coded **Genetic Algorithm (GA)** implementation based on the benchmark formulation by *Simpson et al. (1994)*.

---

## 🌟 Key Features (v1.0.0)

* **EPANET C-Toolkit Integration:** Direct, fast memory interactions with `.inp` network files.
* **Benchmark GA Implementation:** Uses the discrete, integer-coded Genetic Algorithm by *Simpson et al. (1994)* with explicit pressure constraint validation.
* **Modern GUI:** Built with MATLAB App Designer for seamless file loading, parameter tuning, and dynamic progress monitoring.
* **Real-time Visualization:** Live plot updates tracking the global best objective function across generations.
* **Data Export:** Instant export of optimal pipe diameters and cost breakdowns to Microsoft Excel (`.xlsx`).

---

## 📐 Benchmark Reference

The algorithm implemented in v1.0.0 follows:

> **Simpson, A. R., Dandy, G. C., & Murphy, L. J. (1994).**  
> *Optimization of Water Distribution Networks Using Genetic Algorithms.*  
> Journal of Water Resources Planning and Management, ASCE, 120(4), 488-502.

### Tested Benchmark Network:
* **Two-Loop Network:** Reaches the exact global minimum cost of **$419,000**.

---

## 🚀 Getting Started

### Prerequisites
* **MATLAB** R2021b or newer.
* EPANET C-Toolkit dynamic library files (`epanet22.dll` / `epanet2.h` or EPANET MATLAB class wrapper).

### Installation & Execution
1. Clone or download this repository:
   ```bash
   git clone [https://github.com/alirezakhatami98-ui/WDS-Optimizer.git](https://github.com/alirezakhatami98-ui/WDS-Optimizer.git)

```

2. Open MATLAB and navigate to the project directory.
3. Launch the graphical user interface by running:
```matlab
WDS_Optimizer_App

```


4. In the app interface:
* Load your `.inp` network file (e.g., `2loops.inp`).
* Load commercial diameters (`D.txt`) and unit costs (`Cost.txt`).
* Set your Population Size and Maximum Generations.
* Click **Run Optimization**.



---

## 🗺️ Release Roadmap

* [x] **v1.0.0:** GA (Simpson 1994) + MATLAB App Designer GUI + Excel Export.
* [ ] **v1.1.0:** Hydraulic Results Panel (Node Pressures & Pipe Velocities inspection).
* [ ] **v1.2.0:** Multi-constraint handling & customizable penalty formulations.
* [ ] **v2.0.0:** Integration of advanced metaheuristics (SADE, PSO, ACO) with algorithm comparison tools.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
