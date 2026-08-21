# WDS Optimization Toolkit (v1.4.0)

A MATLAB-based Water Distribution Network (WDS) Optimization and Hydraulic Analysis Tool powered by EPANET C-API, Genetic Algorithm (GA), and Particle Swarm Optimization (PSO).

---

## 🌟 What's New in v1.4.0

* **Multi-Algorithm Optimization**: Added drop-down selection support to choose between **Genetic Algorithm (GA)** and **Particle Swarm Optimization (PSO)** engines for comparative heuristic analysis.
* **Discrete PSO Implementation**: Tailored continuous-to-discrete particle position mapping for commercial pipe diameter profiles.
* **Dual Hydraulic Constraints**: Simultaneous pressure ($P_{\min}$) and velocity ($V_{\max}$) penalty functions across both algorithms.
* **100% English Localization**: Fully internationalized UI labels, dialog alerts, and exported tables.

---

## 🛠️ Features

* **GA & PSO Solvers**: Benchmarking metaheuristics for pipe diameter cost optimization.
* **EPANET C-DLL Integration**: Performs fast, dynamic hydraulic network simulations.
* **Tabbed Graphical Interface**: Real-time convergence monitoring, pipe diameter sizing, and node pressure/pipe velocity charts.

---

## 🚀 How to Run

1. Open MATLAB and navigate to the project directory.
2. Launch the application:
   ```matlab
   WDS_Optimizer_App

```

3. Select preferred algorithm (**GA** or **PSO**).
4. Load input files (`.inp`, `D.txt`, and `Cost.txt`).
5. Configure parameters and constraints ($P_{\min}$, $V_{\max}$).
6. Click **Run Optimization**.

---

## 📁 Repository Structure

* `WDS_Optimizer_App.m` - Main MATLAB AppDesigner codebase.
* `2Loops.inp` - Sample EPANET water distribution network.
* `D.txt` - Available commercial pipe diameters profile (inches).
* `Cost.txt` - Unit cost profile for pipe diameters ($/m).

---

## 📜 License

This project is open-source under the MIT License.