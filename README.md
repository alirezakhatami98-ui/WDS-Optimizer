# WDS Optimization Toolkit (v1.1.1)

A MATLAB-based Water Distribution Network (WDS) Optimization and Hydraulic Analysis Tool powered by EPANET C-API and Genetic Algorithm (GA).

---

## 🌟 What's New in v1.1.1

* **Hydraulic Results Analysis Tab**: View detailed hydraulic outputs, including node pressures and pipe flow velocities alongside optimization costs.
* **Pressure Constraint Control**: Interactive user-defined Minimum Pressure limit ($P_{min}$) directly in the GUI.
* **Path & OS Compatibility Fix**: Completely eliminated EPANET path space errors by utilizing clean file handling routines.
* **Multi-Sheet Excel Export**: Export pipe optimization specs and node hydraulic results into separate Excel sheets with one click.

---

## 🛠️ Features

* **Genetic Algorithm Engine**: Optimizes pipe diameters to minimize total construction cost while respecting hydraulic pressure constraints.
* **EPANET C-DLL Integration**: Performs complete hydraulic network solver routines.
* **Tabbed GUI Interface**: Separate views for Convergence Curve/Pipe Costs and Node Pressure distributions.

---

## 🚀 How to Run

1. Open MATLAB and navigate to the project directory.
2. Launch the application:
   ```matlab
   WDS_Optimizer_App
   ```
3. Load the input files (`.inp` network file, `D.txt` diameter set, and `Cost.txt` cost profile).
4. Set the Population Size, Max Generations, and Minimum Pressure ($P_{min}$).
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