# WDS Optimization Toolkit

**MATLAB-based Water Distribution System Optimization Toolkit**

A MATLAB application for optimizing the design of Water Distribution Systems (WDS) using hydraulic simulation through EPANET and population-based metaheuristic optimization algorithms.

**Current Version: 1.7.0**

---

## Overview

The **WDS Optimization Toolkit** is a MATLAB-based software application developed for the optimal design of water distribution networks.

The toolkit combines:

- **EPANET hydraulic simulation**
- **Genetic Algorithm (GA)**
- **Particle Swarm Optimization (PSO)**
- Multiple pipe headloss formulations
- Pressure and velocity constraints
- Fixed-pipe support
- Graphical User Interface (GUI)
- Hydraulic result visualization
- Excel result export

The application allows users to load an EPANET network model together with available pipe diameter and cost data, define hydraulic and optimization parameters, select an optimization algorithm, and obtain an optimized pipe-diameter configuration subject to hydraulic constraints.

---

## Key Features

### 1. EPANET-Based Hydraulic Simulation

The toolkit uses the EPANET MATLAB interface to perform hydraulic simulations of the water distribution network.

For each candidate solution, the selected pipe diameters are assigned to the network and the hydraulic system is solved before evaluating the solution.

This allows the optimization algorithms to directly evaluate candidate network designs according to their hydraulic performance.

---

### 2. Optimization Algorithms

The application currently supports two population-based optimization algorithms.

#### Genetic Algorithm (GA)

The implemented GA includes:

- Random population initialization
- Roulette-wheel selection
- Single-point crossover
- Mutation
- Elitist preservation of the best solution
- Constraint-aware solution evaluation
- Convergence tracking

#### Particle Swarm Optimization (PSO)

The implemented PSO includes:

- Discrete pipe-diameter decision variables
- Particle position and velocity updates
- Personal-best tracking
- Global-best tracking
- Constraint-aware solution evaluation
- Convergence tracking

Both algorithms operate on the same hydraulic optimization problem and use the same evaluation framework.

---

## Hydraulic Headloss Formulations

The application allows the user to select the hydraulic headloss formulation directly from the graphical interface.

Three formulations are supported:

### Hazen-Williams

**EPANET code:** `H-W`

### Darcy-Weisbach

**EPANET code:** `D-W`

### Manning

**EPANET code:** `C-M`

The selected formulation is written to a temporary copy of the input EPANET `.inp` file before the network is loaded and simulated.

The original input file is not modified.

---

## Optimization Problem

The optimization problem is formulated as a discrete pipe-diameter optimization problem.

For each variable pipe, the optimizer selects one diameter from the available diameter set.

### Decision Variables

The decision variables represent the selected commercial diameter for each variable pipe.

If a pipe is marked as fixed, its original diameter is retained and is not modified by the optimization algorithm.

---

## Objective Function

The objective is to minimize the total cost of the variable pipes.

The cost is calculated from:

- Pipe length
- Selected pipe diameter
- Corresponding unit cost

The optimization uses the available diameter and cost data supplied by the user.

The total cost is evaluated only for variable pipes. Fixed pipes retain their existing diameter and are excluded from the optimization cost calculation.

---

## Hydraulic Constraints

Two hydraulic constraints are currently supported.

### Minimum Pressure

The user specifies:

`Pmin`

The pressure at each junction must satisfy:

`Pj >= Pmin`

where `Pj` represents junction pressure.

### Maximum Velocity

The user specifies:

`Vmax`

The velocity in each pipe must satisfy:

`V <= Vmax`

The constraint evaluation calculates the total violation of the pressure and velocity constraints.

A solution is considered feasible when the total constraint violation is zero.

---

## Constraint Handling

Constraint violations are explicitly incorporated into the optimization process.

The total violation is calculated as:

- Pressure deficiency below `Pmin`
- Velocity excess above `Vmax`

The GA uses a penalty-based fitness function to discourage infeasible solutions.

The PSO uses feasibility and constraint violation when updating personal-best and global-best solutions.

This allows the optimization algorithms to distinguish between feasible and infeasible network designs.

---

## Fixed Pipes

The application supports fixed pipe IDs.

The user can enter pipe IDs in the GUI, for example:

```text
1, 3, 7
```

These pipes are excluded from the optimization variables.

Their initial EPANET diameters are retained throughout the optimization.

All remaining pipes are treated as variable pipes.

This feature allows existing infrastructure or otherwise predetermined pipes to remain unchanged while the remaining network is optimized.

---

# Input Files

The application requires three user-selected input files:

1. EPANET `.inp` network file
2. Diameter data file (`D.txt`)
3. Cost data file (`Cost.txt`)

---

## 1. EPANET Input File

The `.inp` file contains the EPANET water distribution network model.

It should contain the network information required for hydraulic simulation, including components such as:

- Junctions
- Reservoirs
- Tanks
- Pipes
- Demands
- Elevations
- Hydraulic properties

The application creates a temporary copy of the selected `.inp` file when modifying the headloss formulation.

The original network file remains unchanged.

---

## 2. Diameter File

The diameter file contains the available pipe diameters.

The current implementation loads the values using MATLAB's `load` function.

The values are interpreted as diameter data in the unit expected by the optimization data structure and are converted to millimeters internally.

For example:

```text
4
6
8
10
12
```

---

## 3. Cost File

The cost file contains the corresponding cost values for the available diameters.

The diameter and cost files must contain corresponding entries.

For example:

```text
120
180
260
350
480
```

The first cost corresponds to the first available diameter, the second cost to the second diameter, and so on.

---

# Graphical User Interface

The application provides a graphical interface for configuring and executing an optimization run.

The interface is divided into two main areas:

- **Input Controls & Constraints**
- **Results & Analysis**

---

## Input Controls

The left panel provides the following controls.

### Network Files

- Load `.INP File`
- Load `D.txt`
- Load `Cost.txt`

### Hydraulic Settings

The user can select:

- Hazen-Williams (HW)
- Darcy-Weisbach (DW)
- Manning (CM)

### Optimization Algorithm

The user can select:

- Genetic Algorithm (GA)
- Particle Swarm (PSO)

### Population / Swarm Size

The `Population / Swarm` field determines the number of individuals used by GA or particles used by PSO.

### Maximum Generations / Iterations

The `Max Gen / Iter` field determines the number of optimization iterations.

### Minimum Pressure

The minimum allowable junction pressure can be specified in meters.

### Maximum Velocity

The maximum allowable pipe velocity can be specified in meters per second.

### Fixed Pipe IDs

Pipe IDs that must remain unchanged can be entered in the corresponding field.

---

# Results & Analysis

The right side of the application contains two result tabs.

---

## Optimization & Costs

This tab displays:

### Convergence Plot

The optimization convergence curve shows the progression of the best objective value during the optimization process.

For GA, the horizontal axis represents generations.

For PSO, the horizontal axis represents iterations.

### Pipe Results Table

The pipe results table contains:

- Pipe ID
- Optimized Diameter (mm)
- Pipe Velocity (m/s)

### Optimal Cost

The final objective value is displayed as the optimal network cost.

---

## Hydraulic Results

The Hydraulic Results tab provides hydraulic performance information.

### Pressure Profile

A bar chart displays the calculated junction pressures.

The minimum pressure constraint is displayed on the plot for comparison.

### Velocity Profile

A bar chart displays the calculated pipe velocities.

The maximum velocity constraint is displayed on the plot for comparison.

### Node Results Table

The node table contains:

- Node ID
- Pressure (m)
- Constraint status

Each node is identified as either:

- `Feasible (OK)`
- `Violation (<Pmin)`

### Hydraulic Summary

The interface reports:

- Minimum junction pressure
- Maximum pipe velocity

These values provide a quick assessment of the hydraulic feasibility of the optimized solution.

---

# Excel Export

The application provides an Excel export function for the final optimization results.

The exported workbook contains two sheets.

### `Pipe_Optimization`

Contains:

- Pipe ID
- Optimized diameter
- Pipe velocity

### `Hydraulic_Nodes`

Contains:

- Node ID
- Pressure
- Hydraulic constraint status

The export is performed using MATLAB's `writetable` functionality.

---

# Project Structure

The repository is organized around a main MATLAB application and a set of modular functions.

```text
WDS-Optimizer/
│
├── 64bit/
│   └── EPANET / supporting 64-bit components
│
├── Nets/
│   └── Network-related files
│
├── WDS_Optimizer_App.m
│
├── runGA.m
├── runPSO.m
│
├── evaluatePopulation.m
├── evaluateSolution.m
│
├── calculateFitness.m
├── calculateCost.m
├── checkConstraints.m
├── selectionRoulette.m
│
├── runHydraulicSimulation.m
├── calculateHydraulicResults.m
│
├── loadOptimizationData.m
├── initializeNetwork.m
├── buildOptimizationParams.m
├── createTempInpFile.m
├── UpdateInpHeadlossFormula.m
│
├── createPipeResultsTable.m
├── createNodeResultsTable.m
├── exportResultsToExcel.m
│
├── .gitignore
└── README.md
```

---

# Software Requirements

The application requires:

- MATLAB
- EPANET MATLAB interface / EPANET C-API
- A compatible 64-bit Windows environment

The MATLAB environment must be able to locate and execute the EPANET interface used by the application.

---

# Installation

### 1. Clone or Download the Repository

Obtain the repository from GitHub:

**WDS Optimization Toolkit**

https://github.com/alirezakhatami98-ui/WDS-Optimizer

### 2. Open MATLAB

Launch MATLAB and navigate to the repository directory.

### 3. Verify EPANET Availability

Make sure the EPANET MATLAB interface and required 64-bit components are available to MATLAB.

### 4. Prepare Input Files

Prepare:

```text
Network.inp
D.txt
Cost.txt
```

---

# Running the Application

After MATLAB is configured and the repository directory is active, run:

```matlab
WDS_Optimizer_App
```

The application window will open.

---

## Recommended Workflow

### Step 1 — Load the Network

Click:

**Load .INP File**

and select the EPANET network file.

### Step 2 — Load Diameter Data

Click:

**Load D.txt**

and select the available diameter data file.

### Step 3 — Load Cost Data

Click:

**Load Cost.txt**

and select the corresponding cost data file.

### Step 4 — Select Headloss Formula

Choose one of:

- Hazen-Williams
- Darcy-Weisbach
- Manning

### Step 5 — Select Optimization Algorithm

Choose:

- Genetic Algorithm
- Particle Swarm

### Step 6 — Configure Optimization Parameters

Specify:

- Population / swarm size
- Maximum generations / iterations
- Minimum pressure
- Maximum velocity

### Step 7 — Define Fixed Pipes

If required, enter the pipe IDs that must remain unchanged.

For example:

```text
1, 3, 5
```

### Step 8 — Run Optimization

Click:

**Run Single Optimization**

The application will perform the optimization and update the results.

### Step 9 — Analyze Results

Review:

- Convergence curve
- Optimal cost
- Pipe diameters
- Pipe velocities
- Junction pressures
- Constraint status

### Step 10 — Export Results

Click:

**Export Excel (Multi-Sheet)**

to save the optimization results as an Excel workbook.

---

# Optimization Workflow

The overall computational workflow can be summarized as follows:

```text
User Input
    │
    ├── EPANET Network
    ├── Diameter Data
    ├── Cost Data
    ├── Hydraulic Constraints
    └── Algorithm Parameters
            │
            ▼
    Load Optimization Data
            │
            ▼
    Create Temporary INP File
            │
            ▼
    Set Headloss Formulation
            │
            ▼
    Initialize EPANET Network
            │
            ▼
    Build Optimization Parameters
            │
            ▼
    Initialize GA / PSO
            │
            ▼
    Generate Candidate Solutions
            │
            ▼
    Assign Pipe Diameters
            │
            ▼
    Run EPANET Hydraulic Simulation
            │
            ▼
    Calculate Cost
            │
            ▼
    Check Pressure & Velocity Constraints
            │
            ▼
    Update Optimization Algorithm
            │
            ▼
    Repeat Until Maximum Iterations
            │
            ▼
    Final Optimized Solution
            │
            ▼
    Hydraulic Analysis & Visualization
            │
            ▼
    Excel Export
```

---

# Important Implementation Details

### Discrete Diameter Selection

The optimization does not treat pipe diameter as a continuous variable.

Each decision variable corresponds to an index in the available diameter set.

This ensures that optimized designs use the provided diameter options.

### Fixed Infrastructure

Fixed pipes are excluded from the optimization variables and retain their initial network diameters.

### Hydraulic Evaluation

Every candidate solution is evaluated through a hydraulic simulation before its objective value and constraint status are determined.

### Junction Pressure

Pressure constraints are evaluated on EPANET junction nodes.

### Pipe Velocity

Velocity constraints are evaluated for the network pipes.

---

# Error Handling

The application provides user-facing alerts for important runtime conditions, including:

- Missing input files
- Invalid file selection
- File paths containing spaces
- Runtime execution errors

The application also displays its current state through the status label, including:

```text
Status: Ready
Status: Running Optimization...
Status: Completed Successfully!
Status: Error occurred!
```

---

# License

This project is released under the **MIT License**.

---

# Author

**Seyed Alireza Khatami**

GitHub:

https://github.com/alirezakhatami98-ui

Repository:

https://github.com/alirezakhatami98-ui/WDS-Optimizer