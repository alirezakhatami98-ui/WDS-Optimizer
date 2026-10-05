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
* Evaluation caching
* Optional parallel hydraulic evaluation

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

The hydraulic evaluation layer reuses the initialized EPANET object during sequential optimization evaluation rather than creating a new EPANET object for every candidate solution.

When optional parallel evaluation is enabled, each MATLAB worker maintains its own EPANET object for the duration of the optimization evaluation session.

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
* Feasibility-aware final solution selection
* Convergence tracking
* Fixed-pipe support
* Evaluation caching
* Optional parallel hydraulic evaluation

The GA uses constraint-aware fitness evaluation to guide the search toward solutions with lower constraint violation.

The crossover and mutation probabilities are stored in the algorithm `Config` structure as `Config.GA.Pc` and `Config.GA.Pm`.

The final GA solution is selected using feasibility-aware logic: feasible solutions are preferred, and among feasible solutions the solution with the lowest cost is retained. If no feasible solution is found, the best available infeasible solution is returned based on constraint violation.

The current default GA configuration uses:

```text
Pc = 0.8
Pm = 0.03
```

These values are treated as algorithm configuration defaults rather than universal optimal values for all WDS optimization problems.

## Particle Swarm Optimization (PSO)

The implemented PSO currently includes:

* Discrete pipe-diameter decision variables
* Particle position and velocity updates
* Personal-best tracking
* Global-best tracking
* Constraint-aware solution evaluation
* Convergence tracking
* Fixed-pipe support
* Evaluation caching
* Optional parallel hydraulic evaluation

For PSO, Personal Best and Global Best updates use the same feasibility-aware policy. Feasible solutions are preferred over infeasible solutions; among feasible solutions lower cost is preferred, while among infeasible solutions lower constraint violation is preferred.

The PSO operates on discrete pipe-diameter decisions represented by integer diameter indices. Particle positions and velocities are maintained internally as continuous search states, while evaluated positions are converted to valid discrete diameter indices using rounding and boundary clamping.

This approach was reviewed through synthetic discretization, boundary, velocity, repeated-index, and fixed-pipe tests. The existing mechanism was retained because the validation did not identify a structural need for a more complex discrete PSO mechanism.

The PSO parameters are maintained in the `Config.PSO` structure:

```text
Config.PSO.w = 0.7
Config.PSO.c1 = 1.5
Config.PSO.c2 = 1.5
```

These values are internal algorithm configuration defaults and are not exposed as GUI controls.

Both algorithms use the same centralized hydraulic constraint semantics through the common optimization evaluation framework.

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
Problem.JunctionIndices
```

`Problem.JunctionIndices` contains the static indices of EPANET junction nodes used for pressure evaluation.

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

For constraint evaluation, pressure violation is normalized by the minimum pressure limit:

```text
PressureViolation = max(0, (Pmin - Pj) / Pmin)
```

The aggregate pressure violation is calculated as the mean normalized violation across the evaluated junctions.

## Maximum Velocity

The user specifies:

```text
Vmax
```

Pipe velocity must satisfy:

```text
V <= Vmax
```

For constraint evaluation, velocity violation is normalized by the maximum velocity limit:

```text
VelocityViolation = max(0, (V - Vmax) / Vmax)
```

The aggregate velocity violation is calculated as the mean normalized violation across the evaluated pipes.

## Total Constraint Violation

The total constraint violation is calculated as:

```text
ViolP = mean(PressureViolation)

ViolV = mean(VelocityViolation)

viol = ViolP + ViolV
```

The resulting violation value is dimensionless.

A solution is considered feasible when:

```text
viol = 0
```

The same constraint semantics are used by both GA and PSO through the common optimization evaluation framework.

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

Config.GA.Pc
Config.GA.Pm

Config.PSO.w
Config.PSO.c1
Config.PSO.c2

Config.Parallel.Enabled
Config.Parallel.NumWorkers
```

where:

* `NS` is the population/swarm size.
* `MaxGen` is the maximum number of generations/iterations.
* `Config.GA.Pc` is the GA crossover probability.
* `Config.GA.Pm` is the GA mutation probability.
* `Config.PSO.w` is the PSO inertia weight.
* `Config.PSO.c1` is the PSO cognitive coefficient.
* `Config.PSO.c2` is the PSO social coefficient.
* `Config.Parallel.Enabled` controls whether optional parallel hydraulic evaluation is used.
* `Config.Parallel.NumWorkers` specifies the requested MATLAB worker count when parallel evaluation is enabled.

The GA-specific parameters `Pc` and `Pm`, as well as the PSO parameters `w`, `c1`, and `c2`, are maintained as internal algorithm configuration values and are not exposed as GUI controls.

Parallel execution is also not exposed as a GUI control. It is an internal configuration capability and is disabled by default:

```text
Config.Parallel.Enabled = false
Config.Parallel.NumWorkers = 2
```

The default sequential execution path therefore remains unchanged for normal application use.

The algorithm configuration is constructed by:

```text
algorithms/buildAlgorithmConfig.m
```

This separation ensures that engineering problem data and algorithm execution settings are not mixed together.

The `Problem` structure is shared by GA and PSO, while algorithm-specific search parameters are grouped under their respective configuration sections.

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
* Final solution cost and feasibility status

The results area provides optimization and hydraulic analysis information.

Validation errors occurring during the optimization workflow are caught by the GUI `try/catch` mechanism and presented to the user through a MATLAB GUI alert.

The GUI displays the final solution cost together with its feasibility status, allowing the user to distinguish between a feasible optimized design and an infeasible fallback solution.

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

### Optimization Cost and Feasibility

The final optimization result includes both the solution cost and its feasibility status.

The GUI displays the result in the form:

```text
Cost: $... | Feasible
```

or:

```text
Cost: $... | Infeasible
```

A feasible solution satisfies all hydraulic constraints.

If no feasible solution is found, the optimization workflow may return an infeasible fallback solution. Such a result must be interpreted together with its displayed feasibility status rather than being treated as a fully feasible optimum.

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
│   ├── createEvaluationCache.m
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
├── parallel/
│   ├── cleanupParallelHydraulics.m
│   ├── evaluateParallelHydraulics.m
│   ├── initializeParallelHydraulics.m
│   └── workerEpanetBatchEvaluate.m
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

The `createEvaluationCache.m` utility provides the evaluation-level cache used to avoid repeated hydraulic evaluation of identical candidate chromosomes during an optimization run.

The `algorithms` directory contains the optimization algorithms and algorithm configuration construction.

The `parallel` directory contains the optional parallel hydraulic evaluation layer. It manages worker-side EPANET initialization, batch hydraulic evaluation, and worker-side EPANET cleanup.

The `hydraulics` directory contains the sequential EPANET hydraulic evaluation and lifecycle management functions.

The `utils` directory contains general-purpose result and export utilities.

The previous `results` directory was reorganized into `utils` during the repository architecture refactoring.

The previous `buildOptimizationParams.m` configuration builder was removed during Phase 4. Its responsibilities were separated into the unified `Problem` representation and the algorithm `Config` structure.

---

# Evaluation Cache

The optimization evaluation layer uses a cache to avoid repeating hydraulic simulations for candidate chromosomes that have already been evaluated during the current optimization run.

The cache is created once per optimization execution and is shared by the evaluation calls made by the selected algorithm.

The cache is implemented using:

```text
optimization/createEvaluationCache.m
```

The cache uses candidate chromosomes as keys and stores the corresponding evaluation results:

```text
[cost, violation, feasibility]
```

The evaluation flow is conceptually:

```text
Candidate Chromosome
        │
        ▼
   Cache Lookup
        │
   ┌────┴────┐
   │         │
  HIT       MISS
   │         │
   │         ▼
   │    Hydraulic Evaluation
   │         │
   │         ▼
   │    Cost / Constraint
   │      Evaluation
   │         │
   └────┬────┘
        ▼
 [cost, violation, feasibility]
```

Cache entries are valid only for the lifetime of the current optimization execution.

The cache is maintained in the main MATLAB process and is not shared directly between parallel workers.

The cache is an exact evaluation reuse mechanism. It does not approximate hydraulic results and does not change the optimization objective or constraint definitions.

The effectiveness of caching depends on how frequently the optimization algorithm generates duplicate candidate chromosomes.

During Phase 8 measurements, duplicate evaluations were observed in both algorithms, with particularly high repetition in PSO. Therefore, caching was retained as part of the production evaluation architecture.

---

# Parallel Hydraulic Evaluation

The toolkit supports an optional parallel hydraulic evaluation path for optimization workloads where parallel execution provides a measurable benefit.

The parallel implementation was introduced and validated during Phase 8 after analyzing EPANET and MATLAB compatibility.

## EPANET Worker Architecture

The EPANET-MATLAB Toolkit uses a handle-based EPANET object. Sharing the same EPANET object between MATLAB workers is therefore not used.

Instead, when parallel evaluation is enabled:

* A MATLAB parallel pool is created or reused.
* Each worker initializes its own EPANET object.
* The worker reuses its EPANET object across multiple candidate evaluations.
* Workers evaluate assigned candidate batches.
* Workers return only hydraulic outputs.
* The main MATLAB process calculates cost, constraint violation, and feasibility.
* Worker EPANET objects are explicitly unloaded after the optimization evaluation is complete.

The architecture is:

```text
runGA / runPSO
        │
        ▼
evaluatePopulation
        │
        ├── Cache HIT
        │      └── Reuse [cost, violation, feasibility]
        │
        └── Cache MISS
               │
               ▼
       Hydraulic Evaluation
          ┌────┴────┐
          │         │
     Sequential   Parallel
          │         │
       Main EPANET  Worker EPANET
                    │
             ┌──────┼──────┐
             ▼      ▼      ▼
          Worker  Worker  Worker
             │      │      │
             └──────┼──────┘
                    ▼
              Pj / Vpipes
                    │
                    ▼
           Main-process cost /
           constraint evaluation
                    │
                    ▼
                  Cache
```

The main-process cache is intentionally kept separate from the worker EPANET state.

## Parallel Configuration

Parallel execution is controlled by:

```text
Config.Parallel.Enabled
Config.Parallel.NumWorkers
```

The default configuration is:

```text
Config.Parallel.Enabled = false
Config.Parallel.NumWorkers = 2
```

This means that the standard application workflow remains sequential unless parallel execution is explicitly enabled in the configuration.

Parallel execution is not exposed as a GUI control.

## Parallel Lifecycle

The parallel hydraulic layer provides:

```text
parallel/initializeParallelHydraulics.m
parallel/evaluateParallelHydraulics.m
parallel/cleanupParallelHydraulics.m
parallel/workerEpanetBatchEvaluate.m
```

The lifecycle is:

```text
Initialize MATLAB Pool
        │
        ▼
Initialize EPANET on Each Worker
        │
        ▼
Evaluate Multiple Candidate Batches
        │
        ▼
Return Hydraulic Results
        │
        ▼
Unload EPANET on Workers
```

The MATLAB parallel pool itself is not automatically deleted during optimization cleanup. The cleanup routine unloads the worker-side EPANET objects while allowing the MATLAB session-level pool to remain available for reuse.

If an existing pool already has the requested number of workers, it can be reused.

If an existing pool has a different worker count, the parallel initialization layer recreates the pool with the requested worker count.

---

# Phase 8 Performance Findings

Phase 8 followed a measurement-driven approach:

```text
Measure
   ↓
Identify Bottleneck
   ↓
Understand Cause
   ↓
Evaluate Improvement
   ↓
Implement Only if Justified
   ↓
Regression Test
   ↓
Measure Again
```

The analysis showed that hydraulic simulation dominates optimization execution time.

A representative non-hydraulic benchmark showed that full-diameter construction, cost calculation, and constraint calculation together accounted for only a very small fraction of evaluation time compared with EPANET hydraulic simulation.

A hydraulic evaluation breakdown showed that the dominant component was:

```text
EPANET solveCompleteHydraulics
```

while diameter assignment and result extraction represented smaller portions of the hydraulic evaluation cost.

Therefore, Phase 8 did not attempt unnecessary optimization of already inexpensive non-hydraulic operations.

## Static Junction Indexing

Junction indices are now identified once during network preparation:

```text
Problem.JunctionIndices
```

The hydraulic evaluation then directly extracts the required junction pressures using these precomputed indices.

This avoids repeated node-type queries during every candidate evaluation.

## Evaluation Caching

Repeated candidate chromosomes were measured during both GA and PSO execution.

Representative measurements showed:

* GA duplicate evaluation rate: approximately 80.68% in the measured run.
* PSO duplicate evaluation rate: approximately 98.20% in the measured run.

These results justified introducing exact evaluation caching into the optimization evaluation layer.

The cache avoids repeating hydraulic simulations for candidates already evaluated during the current optimization run.

## Parallel Performance

Parallel hydraulic evaluation was evaluated only after confirming that independent worker-local EPANET objects could operate correctly.

The validated architecture produced exact hydraulic equivalence in the tested workloads, with zero observed pressure or velocity discrepancies between sequential and parallel evaluation.

Representative final performance measurements on the Two-Loop benchmark were:

| Algorithm | Sequential | Parallel | Speedup | Time Reduction |
| --------- | ---------: | -------: | ------: | -------------: |
| GA        |   205.86 s | 134.73 s |   1.53× |         34.56% |
| PSO       |    40.54 s |  33.36 s |   1.22× |         17.72% |

These measurements demonstrate that parallel evaluation can provide a meaningful performance improvement for sufficiently expensive workloads.

However, parallel execution is **not universally faster**.

Synthetic and intermediate tests showed that:

* Parallel worker startup and coordination introduce overhead.
* Small workloads may be slower when executed in parallel.
* Workloads with very high cache-hit rates may provide little work for parallel workers.
* GA and PSO can exhibit different levels of parallel benefit because their candidate-generation and repetition patterns differ.

Therefore, the production configuration keeps:

```text
Config.Parallel.Enabled = false
```

by default.

Parallel evaluation is considered an optional performance capability rather than a mandatory replacement for sequential evaluation.

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
Build Optimization Problem
    │
    ▼
Network/Data Consistency Validation
    │
    ▼
Initialize Optional Parallel Workers
    │
    ▼
Run GA / PSO
    │
    ▼
Evaluation Cache
    │
    ▼
Hydraulic Evaluation
    │
    ▼
Display Results
```

When parallel execution is disabled, the optimization uses the standard sequential EPANET evaluation path.

When parallel execution is enabled, worker-local EPANET objects are initialized before optimization evaluation and unloaded during optimization cleanup.

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

The main EPANET object is created during network initialization and is unloaded after it is no longer required.

When optional parallel evaluation is enabled, additional independent EPANET objects are created on the MATLAB workers. These worker-side objects are also explicitly unloaded.

The lifecycle is designed to cover both normal and exceptional execution paths.

## Main EPANET Lifecycle

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

## Parallel EPANET Lifecycle

When parallel execution is enabled:

```text
Initialize MATLAB Pool
        │
        ▼
Initialize One EPANET Object per Worker
        │
        ▼
Evaluate Candidate Batches
        │
        ▼
Unload Worker EPANET Objects
        │
        ▼
Keep MATLAB Pool Available for Session Reuse
```

The worker-side lifecycle is managed through:

```text
parallel/initializeParallelHydraulics.m
parallel/evaluateParallelHydraulics.m
parallel/cleanupParallelHydraulics.m
parallel/workerEpanetBatchEvaluate.m
```

The parallel cleanup routine unloads worker EPANET objects but does not automatically delete the MATLAB parallel pool.

The main application workflow performs EPANET cleanup in both successful and failed optimization paths.

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
        Optimization Evaluation
                │
                ├── Evaluation Cache
                │
                ├── Sequential Hydraulic Evaluation
                │
                └── Optional Parallel Hydraulic Evaluation
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
* **Optimization** — candidate-solution evaluation, objective calculation, constraint evaluation, and caching.
* **Hydraulics** — sequential EPANET-based hydraulic simulation and lifecycle management.
* **Parallel** — optional worker-based hydraulic evaluation.
* **EPANET** — hydraulic computation engine.

The `Problem` structure contains the engineering optimization problem and is shared by GA and PSO.

The `Config` structure contains algorithm execution settings and is passed separately to the selected optimization algorithm.

The evaluation cache belongs to the optimization evaluation layer rather than to GA or PSO specifically.

The parallel layer is also kept separate from the core algorithm implementations. GA and PSO only provide the evaluation configuration to the common `evaluatePopulation` workflow.

This architecture is intended to improve:

* Maintainability
* Readability
* Testability
* Extensibility
* Separation of concerns

The validation layer introduced in Phase 2 provides an explicit boundary between user-provided configuration and the computational optimization pipeline.

Phase 4 further separates the definition of the optimization problem from the algorithm-specific search configuration.

Phase 8 further separates performance-related evaluation mechanisms from the algorithm search logic by introducing caching and optional worker-based hydraulic evaluation.

Constraint evaluation is centralized in:

```text
optimization/checkConstraints.m
```

Both GA and PSO receive constraint results through the common `evaluateSolution` and `evaluatePopulation` workflow rather than implementing separate pressure and velocity constraint definitions.

This provides a single constraint policy for the optimization algorithms while keeping algorithm-specific search and ranking mechanisms separate.

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

**Status: Completed**

Phase 5 reviewed and refined the constraint evaluation, feasibility handling, and interaction between hydraulic constraints and optimization algorithms.

Completed activities include:

* Analysis of the existing constraint-handling workflow
* Definition of normalized pressure and velocity constraint violations
* Centralized constraint evaluation
* Explicit feasibility determination
* Review of GA penalty-based fitness handling
* Review of PSO feasibility-aware Personal Best and Global Best ranking
* Unification of hydraulic constraint semantics between GA and PSO
* Propagation of final solution feasibility status to the GUI
* Synthetic constraint regression testing
* GA and PSO regression testing on the Two-Loop network

The final Phase 5 implementation uses dimensionless normalized constraint violations and a common feasibility definition across the optimization framework.

---

## Phase 6 — Genetic Algorithm Improvement

**Status: Completed**

Phase 6 reviewed the existing Genetic Algorithm implementation and validated its main search components and execution behavior.

Completed activities include:

* Establishment of a GA baseline and experimental protocol
* Review of discrete population initialization
* Validation of variable-pipe handling during population initialization
* Validation of roulette-wheel selection
* Statistical verification of selection probability behavior
* Review of single-point crossover
* Review of mutation
* Statistical verification of crossover and mutation probabilities
* Review of elitist preservation
* Review of feasibility-aware solution handling
* Review of convergence tracking
* Separation of GA crossover and mutation parameters into the `Config` structure
* Definition of internal default values for `Pc` and `Pm`
* Multiple independent GA regression runs
* GA regression against PSO
* Verification of GA output consistency

The final Phase 6 implementation preserves the existing GA search mechanisms because the review and statistical tests confirmed that the initialization, selection, crossover, mutation, elitism, and feasibility-aware handling are structurally consistent with the current discrete optimization representation.

No additional GA tuning or GUI controls were introduced during this phase.

The current GA configuration uses:

```text
Config.NS
Config.MaxGen
Config.GA.Pc = 0.8
Config.GA.Pm = 0.03
```

The GA remains stochastic, so repeated executions may produce different feasible costs. Multiple independent regression runs on the Two-Loop network produced feasible solutions, and GA/PSO regression testing confirmed that the Phase 6 changes did not introduce a regression in the PSO workflow.

---

## Phase 7 — Discrete PSO Improvement

**Status: Completed**

Phase 7 evaluated the existing PSO implementation for discrete pipe-diameter optimization.

Completed activities include:

* Analysis of the existing PSO position and velocity representation
* Review of discrete diameter-index handling
* Validation of rounding and boundary clamping behavior
* Synthetic testing of small and large velocity effects
* Testing of repeated discrete diameter indices
* Review and validation of Personal Best and Global Best ranking
* Identification and correction of a feasibility-aware ranking issue
* Validation that feasible solutions dominate infeasible solutions
* Validation of lower-cost preference among feasible solutions
* Validation of lower-violation preference among infeasible solutions
* Separation of PSO parameters into the `Config.PSO` structure
* Fixed-pipe regression testing
* Multiple independent PSO regression runs on the Two-Loop network
* Final GA and PSO regression testing
* Verification of PSO output consistency and convergence reporting

The existing PSO discrete evaluation mechanism was retained because the validation did not identify a structural need for a more complex discrete PSO mechanism.

The corrected feasibility-aware ranking policy is:

1. Feasible solutions are preferred over infeasible solutions.
2. Among feasible solutions, lower cost is preferred.
3. Among infeasible solutions, lower constraint violation is preferred.

The Phase 7 changes preserve the existing `Problem` representation, constraint semantics, GUI workflow, and PSO interface while improving the correctness and organization of the algorithm implementation.

---

## Phase 8 — Performance Optimization

**Status: Completed**

Phase 8 reviewed the optimization evaluation pipeline with a measurement-driven approach.

The guiding process was:

```text
Measure
   ↓
Identify Bottleneck
   ↓
Understand Cause
   ↓
Evaluate Possible Improvement
   ↓
Implement Only if Justified
   ↓
Regression Test
   ↓
Measure Again
```

Completed activities include:

* Establishment of a performance baseline
* Analysis of hydraulic evaluation overhead
* Identification of repeated candidate evaluations
* Measurement of duplicate candidate rates
* Introduction of exact evaluation caching
* Measurement and selection of cache lookup strategy
* Static caching of junction indices
* Analysis of EPANET object lifecycle during evaluation
* Measurement of non-hydraulic evaluation overhead
* Measurement of hydraulic evaluation components
* Analysis of variable-pipe versus full-pipe diameter assignment
* Analysis of the feasibility of hydraulic-result reuse
* Analysis of EPANET compatibility with MATLAB parallel workers
* Prototype testing of persistent worker-local EPANET objects
* Implementation of optional parallel hydraulic evaluation
* Integration of parallel evaluation into the common `evaluatePopulation` workflow
* Worker-side EPANET lifecycle management
* Sequential and parallel numerical-equivalence testing
* GA parallel regression testing
* PSO parallel regression testing
* Existing-pool reuse testing
* No-pool sequential regression testing
* GUI regression testing with sequential execution
* GUI regression testing with parallel execution
* Final performance validation
* Removal of temporary performance instrumentation and benchmark artifacts

### Evaluation Cache

The Phase 8 analysis identified substantial repetition in candidate evaluations.

Representative measured duplicate rates included:

```text
GA: approximately 80.68%
PSO: approximately 98.20%
```

The exact evaluation cache was therefore integrated into the common evaluation layer.

The cache stores:

```text
[cost, violation, feasibility]
```

for previously evaluated candidate chromosomes.

Caching does not alter the objective function, constraint semantics, or optimization algorithms. It only avoids repeating an already completed exact evaluation.

### Static Hydraulic Data

The junction indices required for pressure evaluation are now identified once during network preparation and stored in:

```text
Problem.JunctionIndices
```

This avoids repeated node-type queries during candidate evaluation.

### Hydraulic Bottleneck

Phase 8 measurements showed that hydraulic simulation dominates evaluation cost.

Non-hydraulic operations such as full-diameter construction, cost calculation, and constraint calculation represented only a small fraction of total evaluation time compared with EPANET hydraulic simulation.

Hydraulic measurements further showed that:

```text
solveCompleteHydraulics
```

is the dominant component of the hydraulic evaluation.

Therefore, Phase 8 did not introduce unnecessary optimization of already inexpensive non-hydraulic calculations.

### Parallel Hydraulic Evaluation

EPANET compatibility with MATLAB workers was evaluated before implementation.

The final implementation uses independent worker-local EPANET objects rather than attempting to share one EPANET object across workers.

The implementation was integrated into the common evaluation layer and validated with sequential/parallel equivalence tests.

Representative final performance measurements on the Two-Loop benchmark were:

| Algorithm | Sequential | Parallel | Speedup | Time Reduction |
| --------- | ---------: | -------: | ------: | -------------: |
| GA        |   205.86 s | 134.73 s |   1.53× |         34.56% |
| PSO       |    40.54 s |  33.36 s |   1.22× |         17.72% |

These results justify retaining parallel evaluation as an optional capability.

However, the tests also demonstrated that parallel execution is not universally faster. Small workloads and workloads with high cache-hit rates can suffer from parallel coordination overhead.

Therefore:

```text
Config.Parallel.Enabled = false
```

remains the production default.

Parallel execution is an optional performance capability and is not exposed through the GUI.

Phase 8 did not modify:

* GA search logic
* PSO search logic
* Constraint semantics
* GA penalty coefficient
* PSO ranking policy
* GUI behavior
* Objective definition

The purpose of Phase 8 was performance improvement at the evaluation layer while preserving the existing optimization behavior.

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

**Phase 5:** Completed

**Phase 6:** Completed

**Phase 7:** Completed

**Phase 8:** Completed

**Current next phase:** Phase 9 — Reproducibility

The repository has completed its initial architecture refactoring, input validation/configuration layer, temporary-file and EPANET lifecycle management, unified optimization problem representation, constraint-handling refinement, Genetic Algorithm review, Particle Swarm Optimization review, and performance optimization.

Phase 8 analyzed the optimization evaluation pipeline using measured performance data rather than speculative optimization.

The analysis identified hydraulic simulation as the dominant execution cost and showed substantial repetition of candidate evaluations. An exact evaluation cache was therefore introduced into the common evaluation layer.

Static junction indexing was also introduced to avoid repeated network metadata queries during hydraulic evaluation.

EPANET compatibility with MATLAB parallel workers was evaluated before implementing optional parallel hydraulic evaluation. The final architecture uses independent worker-local EPANET objects and preserves the main-process evaluation cache.

Parallel evaluation was validated for both GA and PSO, including numerical-equivalence tests, worker lifecycle tests, existing-pool reuse, GUI integration, and final performance measurements.

The measured Two-Loop benchmark results showed approximately:

```text
GA: 1.53× parallel speedup
PSO: 1.22× parallel speedup
```

while additional tests demonstrated that parallel execution is not universally faster. For this reason, parallel execution remains disabled by default and is not exposed as a GUI control.

Phase 8 preserved the existing GA/PSO search mechanisms, constraint semantics, objective definition, GUI workflow, and optimization interfaces.

The project will continue through the remaining development phases incrementally, with functional testing performed after each major change.