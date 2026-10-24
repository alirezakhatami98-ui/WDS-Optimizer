function md = buildReportMarkdown(Exp)
%BUILDREPORTMARKDOWN Assemble the full Markdown report.

    C   = Exp.ExperimentResult.Configuration;
    Prb = Exp.Problem;
    Env = Exp.Environment;
    U   = Prb.Units;
    if isempty(U)
        U.PressureUnit = 'm';
        U.VelocityUnit = 'm/s';
        U.DiameterUnit = 'mm';
        U.LengthUnit = 'm';
        U.FlowUnit = 'LPS';
        U.System = 'SI';
    end

    md = strings(0, 1);

    % ---------------- Header ----------------
    md(end+1, 1) = "# WDS Optimization Reproducibility Report";
    md(end+1, 1) = "";
    md(end+1, 1) = "Generated: **" + string(Exp.Timestamp) + "**  ";
    md(end+1, 1) = "App Version: **" + string(Exp.AppVersion) + "**  ";
    md(end+1, 1) = "Experiment ID: **" + string(Exp.ExperimentResult.Metadata.ExperimentID) + "**  ";
    md(end+1, 1) = "Network: **" + string(Env.InpFileName) + "**";
    md(end+1, 1) = "";

    % ---------------- Section 1: Inputs ----------------
    md(end+1, 1) = "## 1. Input Files & Integrity";
    md(end+1, 1) = "";
    md(end+1, 1) = "| File | SHA-256 |";
    md(end+1, 1) = "|------|---------|";
    md(end+1, 1) = "| `" + string(Env.InpFileName) + "` | `" + ...
        string(extractBefore(Env.InpFileHash, 17)) + "…` |";
    md(end+1, 1) = "| `" + string(Env.DFileName) + "` | `" + ...
        string(extractBefore(Env.DFileHash, 17)) + "…` |";
    md(end+1, 1) = "| `" + string(Env.CostFileName) + "` | `" + ...
        string(extractBefore(Env.CostFileHash, 17)) + "…` |";
    md(end+1, 1) = "";
    md(end+1, 1) = "Full inputs are bundled in `inputs/` with complete " + ...
        "hashes in `inputs/manifest.txt`.";
    md(end+1, 1) = "";

    % ---------------- Section 2: Network ----------------
    md(end+1, 1) = "## 2. Network Summary";
    md(end+1, 1) = "";
    md(end+1, 1) = sprintf("- **Flow units**: %s (system: %s)", ...
        U.FlowUnit, U.System);
    md(end+1, 1) = sprintf("- **Pipe diameter unit**: %s", U.DiameterUnit);
    md(end+1, 1) = sprintf("- **Length unit**: %s", U.LengthUnit);
    md(end+1, 1) = sprintf("- **Number of pipes**: %d", Prb.NP);
    md(end+1, 1) = sprintf("- **Number of junctions**: %d", ...
        numel(Prb.JunctionIndices));
    md(end+1, 1) = sprintf("- **Variable pipes**: %d", ...
        numel(Prb.VariablePipes));
    if isempty(Prb.FixedPipes)
        md(end+1, 1) = "- **Fixed pipes**: none";
    else
        md(end+1, 1) = sprintf("- **Fixed pipes**: %s", ...
            formatPipeList(Prb.FixedPipes));
    end
    md(end+1, 1) = sprintf("- **Headloss formula**: %s", Env.Headloss);
    md(end+1, 1) = sprintf("- **Pmin constraint**: %.2f %s", ...
        Prb.Pmin, U.PressureUnit);
    md(end+1, 1) = sprintf("- **Vmax constraint**: %.2f %s", ...
        Prb.Vmax, U.VelocityUnit);
    md(end+1, 1) = "";

    % ---------------- Section 3: Algorithm Config ----------------
    md(end+1, 1) = "## 3. Algorithm Configuration";
    md(end+1, 1) = "";
    md(end+1, 1) = "| Parameter | Value |";
    md(end+1, 1) = "|-----------|-------|";
    md(end+1, 1) = sprintf("| Algorithms | %s |", strjoin(C.Algorithms, ' + '));
    md(end+1, 1) = sprintf("| Runs per algorithm | %d |", C.NumberOfRuns);
    md(end+1, 1) = sprintf("| Population / Swarm size | %d |", C.NS);
    md(end+1, 1) = sprintf("| Max Generations / Iterations | %d |", C.MaxGen);
    md(end+1, 1) = sprintf("| Cache mode | %s |", C.CacheMode);
    md(end+1, 1) = "";

    % ---------------- Section 4: Reproducibility ----------------
    md(end+1, 1) = "## 4. Reproducibility";
    md(end+1, 1) = "";
    md(end+1, 1) = sprintf("**Experiment seed**: `%.0f`", ...
        C.ExperimentSeed);
    md(end+1, 1) = "";
    md(end+1, 1) = "Each run uses a deterministically derived seed:";
    md(end+1, 1) = "";
    md(end+1, 1) = "| Run | Seed |";
    md(end+1, 1) = "|-----|------|";
    for r = 1:numel(Exp.ExperimentResult.RunSeeds)
        md(end+1, 1) = sprintf("| %d | `%.0f` |", r, ...
            Exp.ExperimentResult.RunSeeds(r)); %#ok<AGROW>
    end
    md(end+1, 1) = "";
    md(end+1, 1) = "**Reproduce this experiment:**";
    md(end+1, 1) = "";
    md(end+1, 1) = "```matlab";
    md(end+1, 1) = "% 1. Load the saved experiment";
    md(end+1, 1) = "app = runWDSOptimizer();";
    md(end+1, 1) = "% 2. Load this .wdsx file (if saved separately)";
    md(end+1, 1) = "% 3. Run Experiment again — identical seeds produce";
    md(end+1, 1) = "%    identical results (given the same MATLAB build).";
    md(end+1, 1) = "```";
    md(end+1, 1) = "";
    md(end+1, 1) = "**Software environment recorded with this experiment:**";
    md(end+1, 1) = sprintf("- MATLAB: %s (%s)", ...
        string(Exp.ExperimentResult.Metadata.Version), computer);
    md(end+1, 1) = "- Toolbox: EPANET-MATLAB Toolkit 2.3.5.2";
    md(end+1, 1) = "";

    % ---------------- Section 5: Results ----------------
    md(end+1, 1) = "## 5. Results";
    md(end+1, 1) = "";
    md(end+1, 1) = sprintf("**Best cost**: %.2f", Exp.Best.Score);
    if Exp.Best.Feasible
        md(end+1, 1) = "**Status**: ✅ Feasible design";
    else
        md(end+1, 1) = "**Status**: ⚠️ Infeasible design";
    end
    md(end+1, 1) = sprintf("**Best algorithm**: %s (run %d)", ...
        Exp.Best.Algorithm, Exp.Best.RunIndex);
    md(end+1, 1) = "";
    md(end+1, 1) = "### Per-Algorithm Statistics";
    md(end+1, 1) = "";

    Algorithms = C.Algorithms;
    Headers = {'Algorithm', 'Runs', 'Successful', 'Feasible', ...
        'Feasibility %', 'Best Cost', 'Mean Cost', 'Std Cost', ...
        'Mean Time (s)'};
    Data = cell(numel(Algorithms), numel(Headers));

    for a = 1:numel(Algorithms)
        Name = Algorithms{a};
        St = Exp.ExperimentResult.Results.(Name).Statistics;
        Data{a, 1}  = Name;
        Data{a, 2}  = St.TotalRuns;
        Data{a, 3}  = St.SuccessfulRuns;
        Data{a, 4}  = St.FeasibleRuns;
        Data{a, 5}  = sprintf('%.1f', 100 * St.FeasibilityRate);
        Data{a, 6}  = sprintf('%.2f', St.BestCost);
        Data{a, 7}  = sprintf('%.2f', St.MeanCost);
        Data{a, 8}  = sprintf('%.2f', St.StdCost);
        Data{a, 9}  = sprintf('%.2f', St.MeanTime);
    end

    md = [md; markdownTable(Headers, Data)];
    md(end+1, 1) = "";

    % ---------------- Section 6: Best Design ----------------
    md(end+1, 1) = "## 6. Optimal Pipe Design";
    md(end+1, 1) = "";
    md(end+1, 1) = "| Pipe ID | Diameter (" + string(U.DiameterUnit) + ...
        ") | Velocity (" + string(U.VelocityUnit) + ") |";
    md(end+1, 1) = "|---------|------------|-----------|";

    for p = 1:Prb.NP
        md(end+1, 1) = sprintf("| %d | %.2f | %.3f |", ...
            p, Exp.Best.Position(p), Exp.Hydraulics.PipeVelocities(p)); %#ok<AGROW>
    end
    md(end+1, 1) = "";

    % ---------------- Section 7: Hydraulic Verification ----------------
    md(end+1, 1) = "## 7. Hydraulic Verification";
    md(end+1, 1) = "";
    md(end+1, 1) = sprintf("- **Minimum pressure**: %.3f %s (constraint: ≥ %.2f %s)", ...
        min(Exp.Hydraulics.NodePressures), U.PressureUnit, ...
        Prb.Pmin, U.PressureUnit);
    md(end+1, 1) = sprintf("- **Maximum velocity**: %.3f %s (constraint: ≤ %.2f %s)", ...
        max(Exp.Hydraulics.PipeVelocities), U.VelocityUnit, ...
        Prb.Vmax, U.VelocityUnit);

    if Exp.Hydraulics.Converged
        md(end+1, 1) = "- **Hydraulic solver**: ✅ Converged";
    else
        md(end+1, 1) = "- **Hydraulic solver**: ⚠️ Did not converge";
    end
    md(end+1, 1) = "";

    % ---------------- Section 8: Figures ----------------
    md(end+1, 1) = "## 8. Figures";
    md(end+1, 1) = "";

    for a = 1:numel(Algorithms)
        Alg = Algorithms{a};
        D = Exp.ExperimentResult.Results.(Alg).ConvergenceData;
        if isempty(D.Generation), continue; end
        block = [
            "### " + string(Alg) + " Convergence"
            ""
            "![Convergence " + string(Alg) + "](figures/convergence_" + ...
                string(Alg) + ".png)"
            ""
        ];
        md = [md; block]; %#ok<AGROW>
    end

    md(end+1, 1) = "### Node Pressures";
    md(end+1, 1) = "";
    md(end+1, 1) = "![Node Pressures](figures/pressure_profile.png)";
    md(end+1, 1) = "";
    md(end+1, 1) = "### Pipe Velocities";
    md(end+1, 1) = "";
    md(end+1, 1) = "![Pipe Velocities](figures/velocity_profile.png)";
    md(end+1, 1) = "";
    md(end+1, 1) = "### Final Cost Distribution";
    md(end+1, 1) = "";
    md(end+1, 1) = "![Cost Distribution](figures/cost_distribution.png)";
    md(end+1, 1) = "";
    % ---------------- Section 9: Data Files ----------------
    md(end+1, 1) = "## 9. Data Files";
    md(end+1, 1) = "";
    md(end+1, 1) = "The following tabular data accompanies this report:";
    md(end+1, 1) = "";
    md(end+1, 1) = "| File | Contents |";
    md(end+1, 1) = "|------|----------|";
    md(end+1, 1) = "| `data/results.xlsx` | Multi-sheet Excel: design, " + ...
        "nodes, statistics, runs, convergence |";
    md(end+1, 1) = "| `data/best_design.csv` | Optimal pipe diameters and " + ...
        "velocities |";
    md(end+1, 1) = "| `data/all_runs.csv` | Every run with seed, status, cost |";
    md(end+1, 1) = "| `data/convergence_raw.csv` | Per-generation mean/min/max |";
    md(end+1, 1) = "";

    % ---------------- Footer ----------------
    md(end+1, 1) = "---";
    md(end+1, 1) = "";
    md(end+1, 1) = "_This report was generated automatically by " + ...
        "WDS Optimization Toolkit. All numbers, seeds, and " + ...
        "inputs are recorded exactly as executed._";
end