# WDS Optimization Toolkit (v1.3.0)

A MATLAB-based Water Distribution Network (WDS) Optimization and Hydraulic Analysis Tool powered by EPANET C-API and Genetic Algorithm (GA).

---

## 🌟 What's New in v1.3.0

* **Dual Hydraulic Constraints Support**: Integrated Maximum Pipe Velocity ($V_{\max}$) penalty function alongside Minimum Junction Pressure ($P_{\min}$) constraints in the GA optimization engine.
* **Fully Internationalized Codebase**: Complete transition to English for all GUI components, warning dialogs, and code documentation.
* **Dynamic Hydraulic Plots**: Real-time reference lines for user-defined $P_{\min}$ and $V_{\max}$ limits on pressure and velocity distribution charts.
* **Enhanced Excel Export**: Export pipe sizes, velocities, and node pressure distributions into structured multi-sheet Excel workbooks.

---

## 🛠️ Features

* **Genetic Algorithm Engine**: Optimizes pipe network diameters to minimize total investment costs subject to hydraulic velocity and pressure constraints.
* **EPANET C-DLL Integration**: Directly executes native EPANET hydraulic solver routines.
* **Tabbed GUI Interface**: Separate views for Convergence Profile, Cost Summary, and Hydraulic Plots/Tables.

---

## 🚀 How to Run

1. Open MATLAB and navigate to the project directory.
2. Launch the application:
   ```matlab
   WDS_Optimizer_App
   ```
3. Load the input files (`.inp` network file, `D.txt` diameter set, and `Cost.txt` cost profile).
4. Set Algorithm Parameters (Population Size, Max Generations) and Constraints ($P_{\min}$, $V_{\max}$).
5. Click **Run Optimization**.

---

## 📁 Repository Structure

* `WDS_Optimizer_App.m` - Main MATLAB AppDesigner codebase.
* `2Loops.inp` - Sample EPANET water distribution network.
* `D.txt` - Available commercial pipe diameters profile (inches).
* `Cost.txt` - Unit cost profile for pipe diameters ($/m).

---

## 📜 License
This project is open-source under the MIT License.