# WDS Optimization Toolkit (v1.2.0)

A MATLAB-based Water Distribution Network (WDS) Optimization and Hydraulic Analysis Tool powered by EPANET C-API and Genetic Algorithm (GA).

---

## 🌟 What's New in v1.2.0

* **Hydraulic Visualization Plots**: Interactive bar charts for Node Pressure Profile and Pipe Velocity Distribution with visual constraint limits ($P_{min}$ and $V_{max}$).
* **Hydraulic Results Tab**: Integrated layout featuring both graphical plots and detailed node/pipe attribute tables.
* **Pressure Constraint Control**: Interactive user-defined Minimum Pressure limit ($P_{min}$) directly in the GUI.
* **Path & OS Compatibility**: Safe EPANET DLL file handling routines eliminating space-in-path errors.
* **Multi-Sheet Excel Export**: Export pipe optimization specs and node hydraulic results into separate Excel sheets.

---

## 🛠️ Features

* **Genetic Algorithm Engine**: Optimizes pipe diameters to minimize total construction cost while respecting hydraulic pressure constraints.
* **EPANET C-DLL Integration**: Performs complete hydraulic network solver routines.
* **Tabbed GUI Interface**: Separate views for Convergence Curve/Pipe Costs and Hydraulic Visualization.

---

## 🚀 How to Run

1. Open MATLAB and navigate to the project directory.
2. Launch the application:
   ```matlab
   WDS_Optimizer_App
   ```
3. Load the input files (`.inp` network file, `D.txt` diameter set, and `Cost.txt` cost profile).
4. Set Population Size, Max Generations, and Minimum Pressure ($P_{min}$).
5. Click **Run Optimization**.

---

## 📁 Repository Structure

* `WDS_Optimizer_App.m` - Main MATLAB AppDesigner codebase.
* `2Loops.inp` - Sample EPANET water distribution network.
* `D.txt` - Available commercial diameters profile.
* `Cost.txt` - Unit cost profile for pipe diameters.

---

## 📜 License
This project is open-source under the MIT License.