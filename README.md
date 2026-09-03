# WDS Optimization Toolkit

**MATLAB-based Water Distribution System Optimization Toolkit**

A MATLAB application for optimizing Water Distribution Systems (WDS) using EPANET hydraulic simulation and population-based optimization algorithms.

**Current Version: 1.7.0**

---

## Overview

The **WDS Optimization Toolkit** is a MATLAB-based engineering application for the optimal design of water distribution networks.

The toolkit combines:

* EPANET hydraulic simulation
* Genetic Algorithm (GA)
* Particle Swarm Optimization (PSO)
* Discrete pipe-diameter optimization
* Multiple hydraulic headloss formulations
* Minimum pressure constraints
* Maximum velocity constraints
* Fixed-pipe support
* Graphical User Interface (GUI)
* Hydraulic result visualization
* Excel result export

The application allows users to load an EPANET network together with available pipe diameter and cost data, configure hydraulic and optimization parameters, select an optimization algorithm, and evaluate optimized pipe-diameter configurations subject to hydraulic constraints.

---

# Current Capabilities

## EPANET Hydraulic Simulation

The toolkit uses the **EPANET-MATLAB Toolkit** to perform hydraulic simulations of candidate network designs.

The EPANET-MATLAB Toolkit used by this project is included in the repository as a project dependency.

Current dependency version:

**EPANET-MATLAB Toolkit 2.3.5.2**

The application therefore does not depend on a user-specific installation path such as:

```text
C:\Users\<username>\Desktop\...
```

The dependency is stored under:

```text
dependencies/EPANET-Matlab-Toolkit-2.3.5.2/
```

---

# Optimization Algorithms

The application currently supports two optimization algorithms.

## Genetic Algorithm (GA)

The implemented GA currently includes:

* Random population initialization
* Roulette-wheel selection
* Single-point crossover
* Mutation
* Elitist preservation of the best solution
* Constraint-aware solution evaluation
* Convergence tracking

## Particle Swarm Optimization (PSO)

The implemented PSO currently includes:

* Discrete pipe-diameter decision variables
* Particle position and velocity updates
* Personal-best tracking
* Global-best tracking
* Constraint-aware solution evaluation
* Convergence tracking

Both algorithms operate on the same hydraulic optimization framework and evaluate candidate solutions through EPANET hydraulic simulation.

---

# Hydraulic Headloss Formulations

The application allows the user to select the hydraulic headloss formulation.

The currently supported formulations are:

### Hazen-Williams

**EPANET code:** `H-W`

### Darcy-Weisbach

**EPANET code:** `D-W`

### Manning

**EPANET code:** `C-M`

The selected formulation is applied to a temporary copy of the user-provided EPANET input file.

The original network input file is not modified.

---

# Optimization Problem

The optimization problem is formulated as a **discrete pipe-diameter optimization problem**.

For each variable pipe, the optimizer selects one diameter from the available diameter set.

## Decision Variables

Each optimization variable represents a selected diameter option for a variable pipe.

Fixed pipes are excluded from the optimization variables and retain their initial network diameters.

---

# Objective Function

The objective is to minimize the total cost associated with the variable pipes.

The cost calculation uses:

* Pipe length
* Selected pipe diameter
* Corresponding cost data

The diameter and cost data supplied by the user determine the available design alternatives.

Fixed pipes are excluded from the optimization cost calculation.

---

# Hydraulic Constraints

The current implementation supports two hydraulic constraints.

## Minimum Pressure

The user specifies:

```text
Pmin
```

Junction pressure must satisfy:

```text
Pj >= Pmin
```

where `Pj` is the pressure at a junction.

## Maximum Velocity

The user specifies:

```text
Vmax
```

Pipe velocity must satisfy:

```text
V <= Vmax
```

Constraint violation is calculated from pressure deficiencies and velocity excesses.

A solution is considered feasible when the total constraint violation is zero.

---

# Fixed Pipes

The application supports fixed pipe IDs.

For example:

```text
1, 3, 7
```

Fixed pipes are excluded from the optimization variables.

Their original EPANET diameters are retained during optimization.

This allows existing infrastructure or predetermined pipes to remain unchanged while the remaining network is optimized.

---

# Input Files

The application uses three main user-provided input files:

1. EPANET `.inp` network file
2. Diameter data file
3. Cost data file

---

## EPANET Network File

The `.inp` file contains the EPANET network model.

It should contain the information required for hydraulic simulation, including elements such as:

* Junctions
* Reservoirs
* Tanks
* Pipes
* Demands
* Elevations
* Hydraulic properties

The application uses a temporary copy when modifying the headloss formulation.

---

## Diameter File

The diameter file contains the available pipe diameter options.

Example:

```text
4
6
8
10
12
```

The values are interpreted according to the current optimization data structure and converted internally as required by the application.

---

## Cost File

The cost file contains the corresponding cost values for the available diameter options.

Example:

```text
120
180
260
350
480
```

The diameter and cost data must contain corresponding entries.

For example, the first cost corresponds to the first diameter, the second cost to the second diameter, and so on.

---

# Graphical User Interface

The application provides a graphical interface for configuring and executing an optimization run.

The interface contains controls for:

* Network input
* Diameter data
* Cost data
* Hydraulic headloss formulation
* Optimization algorithm
* Population / swarm size
* Maximum generations / iterations
* Minimum pressure
* Maximum velocity
* Fixed pipe IDs

The results area provides optimization and hydraulic analysis information.

---

# Results & Analysis

## Optimization & Costs

The optimization results include:

### Convergence Plot

The convergence curve shows the progression of the best objective value during optimization.

For GA, the horizontal axis represents generations.

For PSO, the horizontal axis represents iterations.

### Pipe Results

The pipe results include:

* Pipe ID
* Optimized diameter
* Pipe velocity

### Optimal Cost

The final objective value is displayed as the optimized network cost.

---

## Hydraulic Results

The hydraulic results include:

### Pressure Profile

A pressure profile displays the calculated junction pressures together with the minimum pressure constraint.

### Velocity Profile

A velocity profile displays calculated pipe velocities together with the maximum velocity constraint.

### Node Results

The node results include:

* Node ID
* Pressure
* Constraint status

Nodes can be identified according to their hydraulic constraint status.

### Hydraulic Summary

The application reports hydraulic summary information such as:

* Minimum junction pressure
* Maximum pipe velocity

---

# Excel Export

The application supports Excel export of optimization and hydraulic results.

The exported workbook contains result tables for pipes and nodes.

Typical worksheets include:

```text
Pipe_Optimization
Hydraulic_Nodes
```

The export is implemented using MATLAB table functionality and `writetable`.

---

# Project Structure

The repository is organized into logical modules.

```text
WDS-Optimizer/
│
├── app/
│   └── WDS_Optimizer_App.m
│
├── algorithms/
│   ├── runGA.m
│   ├── runPSO.m
│   └── selectionRoulette.m
│
├── optimization/
│   ├── calculateCost.m
│   ├── calculateFitness.m
│   ├── checkConstraints.m
│   ├── evaluatePopulation.m
│   └── evaluateSolution.m
│
├── hydraulics/
│   ├── calculateHydraulicResults.m
│   ├── createTempInpFile.m
│   ├── initializeNetwork.m
│   ├── runHydraulicSimulation.m
│   └── UpdateInpHeadlossFormula.m
│
├── data/
│   ├── buildOptimizationParams.m
│   └── loadOptimizationData.m
│
├── utils/
│   ├── createNodeResultsTable.m
│   ├── createPipeResultsTable.m
│   └── exportResultsToExcel.m
│
├── dependencies/
│   └── EPANET-Matlab-Toolkit-2.3.5.2/
│
├── networks/
│   └── Project network files
│
├── runWDSOptimizer.m
├── setupWDSOptimizer.m
├── .gitignore
└── README.md
```

The `utils` directory contains general-purpose result and export utilities.

The previous `results` directory was reorganized into `utils` during the repository architecture refactoring.

---

# EPANET-MATLAB Toolkit Dependency

The project includes the required EPANET-MATLAB Toolkit under:

```text
dependencies/EPANET-Matlab-Toolkit-2.3.5.2/
```

The original Toolkit structure is retained inside the dependency directory.

The project does not use the old root-level:

```text
64bit/
```

directory.

The bundled Toolkit contains the platform-specific components required by the original Toolkit distribution.

The project currently targets the MATLAB/Windows environment in which the application has been tested.

---

# Installation

## 1. Obtain the Repository

Clone or download the repository:

**WDS Optimization Toolkit**

https://github.com/alirezakhatami98-ui/WDS-Optimizer

## 2. Open MATLAB

Launch MATLAB and open the project directory.

The repository should be used as the working project directory.

## 3. Configure the Project

Run the project setup procedure:

```matlab
setupWDSOptimizer
```

The setup procedure is responsible for preparing the MATLAB environment for the project and its bundled dependencies.

The project uses repository-relative paths rather than hard-coded paths belonging to a particular user's computer.

## 4. Run the Application

Use:

```matlab
runWDSOptimizer
```

as the project entry point.

The application can then be configured through the graphical interface.

---

# Recommended Workflow

### Step 1 — Start the Project

Launch MATLAB and open the WDS Optimizer repository.

Run the project launcher:

```matlab
runWDSOptimizer
```

### Step 2 — Load the Network

Use:

**Load .INP File**

and select the EPANET network file.

### Step 3 — Load Diameter Data

Use:

**Load D.txt**

and select the available diameter data.

### Step 4 — Load Cost Data

Use:

**Load Cost.txt**

and select the corresponding cost data.

### Step 5 — Select Headloss Formula

Choose one of:

* Hazen-Williams
* Darcy-Weisbach
* Manning

### Step 6 — Select Optimization Algorithm

Choose:

* Genetic Algorithm
* Particle Swarm

### Step 7 — Configure Parameters

Specify:

* Population / swarm size
* Maximum generations / iterations
* Minimum pressure
* Maximum velocity

### Step 8 — Define Fixed Pipes

If required, enter pipe IDs that must remain unchanged.

For example:

```text
1, 3, 5
```

### Step 9 — Run Optimization

Click:

**Run Single Optimization**

The selected optimization algorithm will evaluate candidate designs using EPANET hydraulic simulation.

### Step 10 — Analyze Results

Review:

* Convergence curve
* Optimal cost
* Pipe diameters
* Pipe velocities
* Junction pressures
* Constraint status

### Step 11 — Export Results

Use:

**Export Excel (Multi-Sheet)**

to export the calculated results.

---

# Temporary Files

The application currently creates temporary EPANET files during execution.

Typical temporary files include:

```text
temp_network*.inp
temp_network*.txt
```

These files are runtime artifacts and are not intended to be committed to the repository.

They are excluded through `.gitignore`.

Professional temporary-file lifecycle management is planned for a later development phase.

---

# Development Architecture

The repository is being developed incrementally.

The architecture is intentionally divided into functional layers:

```text
GUI
 │
 ▼
Algorithms
 │
 ▼
Optimization
 │
 ▼
Hydraulics
 │
 ▼
EPANET
```

Supporting data and utility modules are separated from the computational layers.

This structure is intended to improve:

* Maintainability
* Readability
* Testability
* Extensibility
* Separation of concerns

---

# Development Roadmap

The project is being improved through a staged development process.

## Phase 1 — Repository Architecture

**Status: Completed**

Completed activities include:

* Repository organization
* Modular directory structure
* Relocation of MATLAB source files
* Reorganization of result utilities
* Integration of EPANET-MATLAB Toolkit as a project dependency
* Removal of the previous root-level `64bit` directory
* Repository-relative setup/launcher structure
* Dependency path verification
* Functional regression testing

---

## Phase 2 — Input Validation & Configuration

**Status: Next**

Planned work includes systematic validation of:

* Optimization parameters
* Hydraulic constraints
* Diameter data
* Cost data
* Network data
* Fixed pipe IDs
* Network/data consistency

---

## Phase 3 — Temporary Files & EPANET Lifecycle

Planned improvements include:

* Unique temporary files
* Appropriate temporary directories
* Automatic cleanup
* Error-safe cleanup
* Robust EPANET object lifecycle
* Proper unloading during exceptions

---

## Phase 4 — Unified Optimization Problem

A unified optimization problem definition will be developed for GA and PSO.

---

## Phase 5 — Constraint Handling

Constraint evaluation, feasibility and penalty handling will be reviewed and unified.

---

## Phase 6 — Genetic Algorithm Improvement

The GA implementation will be reviewed for:

* Elitism
* Selection
* Crossover
* Mutation
* Infeasible-solution handling
* Stopping criteria
* Best feasible solution
* Convergence tracking

---

## Phase 7 — Discrete PSO Improvement

The suitability of the current PSO implementation for discrete pipe-diameter optimization will be scientifically evaluated.

---

## Phase 8 — Performance Optimization

Potential improvements include:

* Hydraulic evaluation overhead
* Repeated simulations
* Caching
* EPANET object management
* Evaluation performance
* Possible parallel evaluation

Parallel execution will only be considered after compatibility with EPANET and MATLAB has been evaluated.

---

## Phase 9 — Reproducibility

Random seed control will be introduced to support reproducible optimization experiments.

---

## Phase 10 — Benchmark / Experiment Framework

A formal experimental framework will be developed for comparing algorithms using:

* Multiple independent runs
* Best cost
* Mean cost
* Standard deviation
* Execution time
* Feasibility rate
* Convergence comparison

---

## Phase 11 — GUI Enhancement

Planned GUI improvements include:

* Improved validation messages
* Progress indication
* Optimization cancellation
* Feasibility display
* Advanced settings
* Improved result presentation
* Improved error management

---

## Phase 12 — Professional Reporting

The reporting system will be expanded to provide structured optimization and hydraulic reports.

---

## Phase 13 — Testing

The project will progressively include:

* Unit tests
* Integration tests
* Hydraulic validation
* Optimization validation
* Reproducible benchmark networks

---

## Phase 14 — Final Documentation & Release

Final documentation and release preparation will be performed after the architecture and capabilities have stabilized.

---

# Current Development Status

**Version:** `1.7.0`

**Phase 1:** Completed

**Current next phase:** Phase 2 — Input Validation & Configuration

The existing optimization functionality has been tested after the Phase 1 repository refactoring.

Future phases will be implemented incrementally, with functional testing performed after each phase.
