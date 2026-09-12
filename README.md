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
* Structured input and configuration validation

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
* Fixed-pipe support

## Particle Swarm Optimization (PSO)

The implemented PSO currently includes:

* Discrete pipe-diameter decision variables
* Particle position and velocity updates
* Personal-best tracking
* Global-best tracking
* Constraint-aware solution evaluation
* Convergence tracking
* Fixed-pipe support

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

Fixed pipes are excluded from the optimization variables and retain their initial network diameters.

The optimization problem is represented centrally by the `Problem` structure. This provides a unified representation of the engineering optimization problem shared by both GA and PSO.

The current `Problem` structure contains:

```text
Problem.Din
Problem.Cost
Problem.D
Problem.NP
Problem.L
Problem.InitialD
Problem.FixedPipes
Problem.VariablePipes
Problem.Pmin
Problem.Vmax
```

The `Problem` structure contains problem-specific data and constraints, while algorithm execution settings are kept separate in the `Config` structure.

The unified problem representation is constructed by:

```text
optimization/buildOptimizationProblem.m
```

Both optimization algorithms consume the same `Problem` representation. This prevents the optimization problem definition from being duplicated across GA and PSO implementations.

---

# Decision Variables

Each optimization variable represents a selected diameter option for a variable pipe.

If fixed pipes are specified, they are excluded from the optimization search space.

The remaining pipes are treated as variable pipes.

The optimization framework explicitly maintains:

```text
Fixed Pipes
Variable Pipes
```

and validates that these two sets do not overlap and together cover all pipe indices.

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

The fixed-pipe input is validated before optimization.

The validation checks:

* Empty input
* Comma-separated format
* Integer pipe IDs
* Positive pipe IDs
* Pipe ID range
* Duplicate pipe IDs

The resulting fixed-pipe list is standardized and sorted.

---

# Input Validation & Configuration

Input validation was implemented and integrated into the main optimization workflow during **Phase 2**.

The validation layer is responsible for detecting invalid user input and inconsistent optimization/network data before the optimization algorithms are executed.

## Optimization Parameter Validation

The function:

```text
validateOptimizationParameters.m
```

validates:

* Population/swarm size (`NS`)
* Maximum generations/iterations (`MaxGen`)
* Minimum pressure (`Pmin`)
* Maximum velocity (`Vmax`)

The validation checks appropriate numeric, scalar, finite, integer, and positive-value requirements.

Invalid parameters generate descriptive MATLAB errors that are handled by the GUI execution layer.

---

## Diameter and Cost Data Validation

The function:

```text
validateOptimizationData.m
```

validates the available diameter and cost data.

The validation includes:

* Empty data detection
* Numeric data type
* Finite values
* Positive diameter values
* Unique diameter values
* Positive cost values
* Matching number of diameter and cost entries

Diameter and cost arrays must therefore represent a valid one-to-one mapping of available design alternatives.

---

## Fixed Pipe Validation

The function:

```text
validateFixedPipes.m
```

validates fixed-pipe input entered through the GUI.

It checks:

* Empty input
* Input format
* Integer pipe IDs
* Valid pipe ID range
* Duplicate IDs

The validated pipe IDs are sorted before being passed to the optimization configuration.

---

## Network Consistency Validation

The function:

```text
validateNetworkConsistency.m
```

performs consistency checks between the EPANET network and optimization data.

The validation includes:

* Number of pipes (`NP`)
* Pipe length count
* Pipe length validity
* Initial diameter count
* Initial diameter validity
* Diameter data consistency
* Diameter/cost consistency
* Fixed-pipe validity
* Variable-pipe validity
* Fixed/variable pipe overlap
* Complete pipe-index coverage

The validation ensures that fixed and variable pipe sets together represent the complete network pipe index set.

---

# Optimization Configuration

Optimization execution settings are separated from the engineering optimization problem.

The optimization problem is represented by:

```text
Problem
```

and algorithm execution settings are represented by:

```text
Config
```

The current algorithm configuration contains:

```text
Config.NS
Config.MaxGen
```

where:

* `NS` is the population/swarm size.
* `MaxGen` is the maximum number of generations/iterations.

The algorithm configuration is constructed by:

```text
algorithms/buildAlgorithmConfig.m
```

This separation ensures that engineering problem data and algorithm execution settings are not mixed together.

The `Problem` structure is shared by GA and PSO, while each algorithm remains responsible for its own search mechanism.

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

Validation errors occurring during the optimization workflow are caught by the GUI `try/catch` mechanism and presented to the user through a MATLAB GUI alert.

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
│   ├── buildAlgorithmConfig.m
│   ├── runGA.m
│   ├── runPSO.m
│   └── selectionRoulette.m
│
├── optimization/
│   ├── buildOptimizationProblem.m
│   ├── calculateCost.m
│   ├── calculateFitness.m
│   ├── checkConstraints.m
│   ├── evaluatePopulation.m
│   └── evaluateSolution.m
│
├── hydraulics/
│   ├── calculateHydraulicResults.m
│   ├── cleanupEpanetObject.m
│   ├── cleanupTempInpFiles.m
│   ├── createTempInpFile.m
│   ├── initializeNetwork.m
│   ├── runHydraulicSimulation.m
│   └── UpdateInpHeadlossFormula.m
│
├── data/
│   └── loadOptimizationData.m
│
├── validation/
│   ├── validateOptimizationData.m
│   ├── validateOptimizationParameters.m
│   ├── validateFixedPipes.m
│   └── validateNetworkConsistency.m
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

The `validation` directory contains the input and configuration validation layer introduced during Phase 2.

The `optimization` directory contains the centralized optimization problem representation and the optimization evaluation functions.

The `algorithms` directory contains the optimization algorithms and algorithm configuration construction.

The `utils` directory contains general-purpose result and export utilities.

The previous `results` directory was reorganized into `utils` during the repository architecture refactoring.

The previous `buildOptimizationParams.m` configuration builder was removed during Phase 4. Its responsibilities were separated into the unified `Problem` representation and the algorithm `Config` structure.

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

```text
https://github.com/alirezakhatami98-ui/WDS-Optimizer
```

## 2. Open MATLAB

Launch MATLAB and open the project directory.

The repository should be used as the working project directory.

## 3. Configure the Project

Run the project setup procedure:

```matlab
setupWDSOptimizer
```

The setup procedure prepares the MATLAB environment for the project and its bundled dependencies.

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

The application first validates the supplied optimization parameters and configuration data.

If the input passes validation, the selected optimization algorithm evaluates candidate designs using EPANET hydraulic simulation.

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

# Validation Workflow

The current validation flow is integrated into the optimization execution pipeline.

The general execution sequence is:

```text
User Input
    │
    ▼
Optimization Parameter Validation
    │
    ▼
Load Diameter & Cost Data
    │
    ▼
Diameter/Cost Validation
    │
    ▼
Create Temporary INP
    │
    ▼
Update Headloss Formula
    │
    ▼
Initialize EPANET Network
    │
    ▼
Validate Fixed Pipes
    │
    ▼
Build Optimization Parameters
    │
    ▼
Network/Data Consistency Validation
    │
    ▼
Run GA / PSO
    │
    ▼
Hydraulic Evaluation
    │
    ▼
Display Results
```

Validation errors generated during the optimization workflow are propagated to the GUI execution layer and displayed to the user through an error dialog.

This prevents invalid configuration data from silently reaching the optimization algorithms.

---

# Temporary Files

The application creates temporary EPANET input files during optimization.

Temporary files are created using MATLAB's system temporary directory and are uniquely named for each execution.

Typical runtime artifacts include:

```text
<temporary-name>.inp
<temporary-name>.txt
<temporary-name>_temp.inp
<temporary-name>_temp.txt
<temporary-name>_temp.bin
```

These files are runtime artifacts and are not intended to be committed to the repository.

The temporary-file lifecycle is managed automatically.

The application:

* creates a unique temporary INP file
* uses the temporary INP file for EPANET initialization
* preserves the original user-provided INP file
* removes generated temporary files after execution
* performs cleanup during both successful and failed execution paths

Temporary-file cleanup is implemented through:

```text
hydraulics/cleanupTempInpFiles.m
```

The cleanup routine safely checks for generated files before attempting deletion and ignores cleanup errors so that secondary cleanup failures do not mask the original execution error.


---

# EPANET Object Lifecycle

EPANET network objects are explicitly managed during the optimization workflow.

The EPANET object is created during network initialization and is unloaded after it is no longer required.

The lifecycle is designed to cover both normal and exceptional execution paths.

The main lifecycle components are:

```text
Create Temporary INP
        │
        ▼
Initialize EPANET Object
        │
        ▼
Hydraulic / Optimization Evaluation
        │
        ▼
Unload EPANET Object
        │
        ▼
Remove Temporary Files
```

EPANET cleanup is implemented through:

```text
hydraulics/cleanupEpanetObject.m
```

The network initialization routine also protects against initialization failures. If an EPANET object has been created but an error occurs before ownership is returned to the caller, the initialization routine unloads the object before rethrowing the original error.

This prevents EPANET objects from remaining loaded after failed initialization.

The main application workflow also performs EPANET cleanup in both successful and failed optimization paths.

---

# Development Architecture

The repository is divided into functional layers:

```text
GUI
 │
 ├── Validation
 │
 ├── Problem Construction
 │       │
 │       └── Problem
 │
 └── Algorithm Configuration
         │
         └── Config
                │
                ▼
           GA / PSO
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

The main architectural responsibilities are:

* **GUI** — user interaction and execution workflow.
* **Validation** — validation of user input and network/optimization data.
* **Problem Construction** — creation of the unified engineering optimization problem.
* **Algorithm Configuration** — construction of algorithm execution settings.
* **Algorithms** — GA and PSO search mechanisms.
* **Optimization** — candidate-solution evaluation, objective calculation, and constraint evaluation.
* **Hydraulics** — EPANET-based hydraulic simulation.
* **EPANET** — hydraulic computation engine.

The `Problem` structure contains the engineering optimization problem and is shared by GA and PSO.

The `Config` structure contains algorithm execution settings and is passed separately to the selected optimization algorithm.

This architecture is intended to improve:

* Maintainability
* Readability
* Testability
* Extensibility
* Separation of concerns

The validation layer introduced in Phase 2 provides an explicit boundary between user-provided configuration and the computational optimization pipeline.

Phase 4 further separates the definition of the optimization problem from the algorithm-specific search configuration.

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

**Status: Completed**

Phase 2 introduced a structured validation and configuration layer.

Completed activities include:

* Optimization parameter validation
* Hydraulic constraint validation
* Diameter data validation
* Cost data validation
* Fixed pipe ID validation
* Network data consistency validation
* Fixed/variable pipe consistency validation
* Integration of validation into the GUI optimization workflow
* GUI error handling for validation failures
* Construction of a centralized optimization parameter structure
* Functional testing of validation routines
* Regression testing of the complete optimization workflow

The final optimization workflow was tested after the Phase 2 changes and the optimization executed successfully.

---

## Phase 3 — Temporary Files & EPANET Lifecycle

**Status: Completed**

Phase 3 established controlled temporary-file management and explicit EPANET object lifecycle handling.

Completed activities include:

* Unique temporary INP file creation
* Use of MATLAB's temporary directory
* Explicit ownership of temporary files
* Automatic cleanup of temporary EPANET artifacts
* Cleanup after successful execution
* Exception-safe cleanup after failed execution
* Explicit EPANET object unloading
* Exception-safe EPANET cleanup during network initialization
* Cleanup integration into the main optimization workflow
* Regression testing of temporary-file cleanup
* Regression testing of EPANET object unloading
* Verification that temporary `.inp`, `.txt`, and `.bin` files do not remain after successful execution

The Phase 3 implementation preserves the original user-provided EPANET input file and confines generated runtime artifacts to the system temporary directory.


---

## Phase 4 — Unified Optimization Problem

**Status: Completed**

Phase 4 introduced a unified representation of the optimization problem and separated it from algorithm execution configuration.

Completed activities include:

* Analysis of the existing optimization problem representation
* Definition of the unified `Problem` structure
* Centralized construction of the optimization problem
* Migration of GA to the unified `Problem` representation
* Migration of PSO to the unified `Problem` representation
* Separation of algorithm configuration into the `Config` structure
* Introduction of `buildAlgorithmConfig.m`
* Removal of the obsolete `buildOptimizationParams.m`
* Simplification of redundant argument passing
* Separation of EPANET runtime resources from the optimization problem representation
* Review of the optimization evaluation interfaces
* Regression testing of GA and PSO
* Regression testing of hydraulic headloss formulations
* Regression testing of fixed-pipe configurations
* Regression testing of hydraulic constraints
* Regression testing of input and network validation
* Regression testing of temporary-file and EPANET cleanup
* Multiple consecutive optimization runs without restarting MATLAB

The final Phase 4 architecture uses a shared `Problem` representation for both GA and PSO while keeping algorithm execution settings in a separate `Config` structure.

---

## Phase 5 — Constraint Handling

**Status: Planned**

Constraint evaluation, feasibility and penalty handling will be reviewed and unified.

---

## Phase 6 — Genetic Algorithm Improvement

**Status: Planned**

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

**Status: Planned**

The suitability of the current PSO implementation for discrete pipe-diameter optimization will be scientifically evaluated.

---

## Phase 8 — Performance Optimization

**Status: Planned**

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

**Status: Planned**

Random seed control will be introduced to support reproducible optimization experiments.

---

## Phase 10 — Benchmark / Experiment Framework

**Status: Planned**

A formal experimental framework will be developed for comparing algorithms using:

* Multiple independent runs
* Best cost
* Mean cost
* Standard deviation
* Execution time
* Feasibility rate
* Convergence comparison

Benchmark functionality is intentionally not part of the current single-optimization workflow and will be reintroduced in a later development phase.

---

## Phase 11 — GUI Enhancement

**Status: Planned**

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

**Status: Planned**

The reporting system will be expanded to provide structured optimization and hydraulic reports.

---

## Phase 13 — Testing

**Status: Planned / Progressive**

The project will progressively include:

* Unit tests
* Integration tests
* Hydraulic validation
* Optimization validation
* Reproducible benchmark networks

Testing is being introduced incrementally alongside the architectural development phases.

---

## Phase 14 — Final Documentation & Release

**Status: Planned**

Final documentation and release preparation will be performed after the architecture and capabilities have stabilized.

---

# Current Development Status

**Version:** `1.7.0`

**Phase 1:** Completed

**Phase 2:** Completed

**Phase 3:** Completed

**Phase 4:** Completed

**Current next phase:** Phase 5 — Constraint Handling

The repository has completed its initial architecture refactoring, input validation/configuration layer, temporary-file and EPANET lifecycle management, and unified optimization problem representation.

The optimization functionality has been regression-tested after the Phase 4 changes, including repeated GA and PSO executions and multiple supported hydraulic configurations.

The project will continue through the remaining development phases incrementally, with functional testing performed after each major change.
