# WDS Optimization Toolkit (v1.5.0)

A MATLAB-based Water Distribution Network (WDS) Optimization and Hydraulic Analysis Tool powered by EPANET C-API, Genetic Algorithm (GA), and Particle Swarm Optimization (PSO).

---

## 🌟 What's New in v1.5.0

* **Fixed Pipe Diameter Constraints**: Specify fixed pipe IDs (e.g., existing infrastructure) to exclude them from the optimization search space while preserving their initial diameters from the `.inp` file.
* **Multi-Algorithm Support**: Seamlessly switch between **Genetic Algorithm (GA)** and **Particle Swarm Optimization (PSO)** engines for metaheuristic benchmarking.
* **Dual Hydraulic Constraints**: Dynamic penalty logic supporting node minimum pressure ($P_{\min}$) and pipe maximum velocity ($V_{\max}$) constraints.
* **Empty Solution Fallback**: Prevents execution errors when no 100% feasible solution is found by returning the candidate with minimum constraint violation alongside visual alerts.
* **Excel Exporting**: Multi-sheet output containing optimized pipe sizing, flow velocities, and junction pressure profiles.

---

## 🛠️ Features

* **Flexible Variable Sizing**: Supports rehabilitation and expansion projects by fixing existing pipes and optimizing new ones.
* **EPANET C-DLL Engine**: Performs high-speed dynamic hydraulic simulation directly from MATLAB.
* **Tabbed Interface**: Monitor real-time convergence curves, pipe sizing tables, and hydraulic node/pipe bar plots.

---

## 🚀 How to Run

1. Open MATLAB and set the project directory as the active path.
2. Run the application command:
   ```matlab
   WDS_Optimizer_App
   ```
3. Load required input files (`.inp`, `D.txt`, and `Cost.txt`).
4. Select the desired metaheuristic algorithm (**GA** or **PSO**).
5. (Optional) Enter fixed pipe IDs in the **Fixed Pipe IDs** field (e.g., `1, 3` or `1:3`).
6. Set pressure and velocity constraints ($P_{\min}$, $V_{\max}$).
7. Click **Run Optimization**.

---

## 📁 Repository Structure

* `WDS_Optimizer_App.m` - Core MATLAB AppDesigner application.
* `2Loops.inp` - Sample EPANET water distribution network.
* `D.txt` - Commercial pipe diameters profile (inches).
* `Cost.txt` - Pipe unit cost table ($/m).

---

## 📜 License

This project is open-source under the MIT License.