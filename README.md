# WDS Optimization Toolkit (v1.6.0)

A MATLAB-based Water Distribution Network (WDS) Optimization, Hydraulic Benchmark, and Analysis Tool powered by EPANET C-API, Genetic Algorithm (GA), and Particle Swarm Optimization (PSO).

---

## 🌟 What's New in v1.6.0

* **Headloss Formula Selection**: Choose dynamically between **Hazen-Williams (HW)**, **Darcy-Weisbach (DW)**, and **Manning (CM)** friction models directly from the UI.
* **GA vs. PSO Benchmark Engine**: Dedicated evaluation tab with single-click comparative runs plotting dual convergence curves and side-by-side metric tables (Cost, Execution Time, Hydraulic Limits).
* **Multi-Sheet Benchmark Export**: Seamless export of comparative algorithm metrics alongside pipe and node hydraulic outputs to Excel.
* **Fixed Pipe Constraints**: Retained full support for fixed infrastructure IDs during optimizations.

---

## 🛠️ Key Features

* **Headloss Physics Engine**: Full EPANET C-DLL integration with selectable friction formulation.
* **Algorithmic Benchmarking**: Direct performance comparison between Genetic Algorithm (GA) and Particle Swarm Optimization (PSO).
* **Hydraulic Constraints**: Dynamic pressure ($P_{\min}$) and velocity ($V_{\max}$) penalty function enforcement.
* **Interactive UI**: Real-time convergence animation, dual hydraulic profiles, and comprehensive multi-sheet Excel reporting.

---

## 🚀 How to Run & Test

1. Open MATLAB and navigate to the repository directory.
2. Run the application:
   ```matlab
   WDS_Optimizer_App

```

3. Load input files (`.inp`, `D.txt`, and `Cost.txt`).
4. Select the friction formulation (**Hazen-Williams**, **Darcy-Weisbach**, or **Manning**).
5. Choose an algorithm and click **Run Single Optimization**, OR click **Run GA vs PSO Benchmark** to compare both engines side-by-side.
6. Export comprehensive Excel reports from the export button.

---

## 📜 License

This project is open-source under the MIT License.