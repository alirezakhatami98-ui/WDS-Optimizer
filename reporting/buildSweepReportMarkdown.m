function md = buildSweepReportMarkdown(SweepResult, BaseExp)
%BUILDSWEEPREPORTMARKDOWN Assemble the sweep Markdown report.

    Points = SweepResult.Points;
    N = numel(Points);
    ParamLabel = strrep(SweepResult.Parameter, '_', ' ');

    Ok = strcmp({Points.Status}, 'Success');
    Feasible = Ok & logical([Points.BestFeasible]);

    % ---- Find best point ----
    if any(Feasible)
        candidates = find(Feasible);
    elseif any(Ok)
        candidates = find(Ok);
    else
        candidates = [];
    end

    md = strings(0, 1);

    % ============== Header ==============
    md(end+1, 1) = "# WDS Parameter Sensitivity Sweep Report";
    md(end+1, 1) = "";
    md(end+1, 1) = "Generated: **" + string(datetime('now')) + "**  ";
    if ~isempty(BaseExp) && isfield(BaseExp, 'AppVersion')
        md(end+1, 1) = "App Version: **" + string(BaseExp.AppVersion) + "**  ";
    end
    md(end+1, 1) = "Parameter: **" + string(ParamLabel) + "**  ";
    md(end+1, 1) = "Values: **" + string(strjoin( ...
        arrayfun(@(x) sprintf('%g', x), SweepResult.Values(:)', ...
        'UniformOutput', false), ', ')) + "**  ";
    md(end+1, 1) = "Status: **" + string(SweepResult.Status) + "**";
    md(end+1, 1) = "";

    % ============== 1. Executive Summary ==============
    md(end+1, 1) = "## 1. Executive Summary";
    md(end+1, 1) = "";
    if ~isempty(candidates)
        scores = [Points(candidates).BestScore];
        [~, locBest] = min(scores);
        BestIdx = candidates(locBest);
        P = Points(BestIdx);

        if P.BestFeasible
            FeasTag = "✅ feasible";
        else
            FeasTag = "⚠️ infeasible";
        end

        md(end+1, 1) = sprintf( ...
            "**Best configuration: %s = %g** — Best cost: **%.2f** (%s)", ...
            ParamLabel, P.Value, P.BestScore, FeasTag);
        md(end+1, 1) = "";

        if numel(candidates) >= 2
            ranked = sortrows([ ...
                [Points(candidates).Value]', ...
                [Points(candidates).BestScore]'], 2);
            TopN = min(3, size(ranked, 1));

            md(end+1, 1) = "### Top configurations";
            md(end+1, 1) = "";
            md(end+1, 1) = "| Rank | " + string(ParamLabel) + " | Best Cost |";
            md(end+1, 1) = "|------|------------|-----------|";
            for r = 1:TopN
                md(end+1, 1) = sprintf("| %d | %g | %.2f |", ...
                    r, ranked(r, 1), ranked(r, 2)); %#ok<AGROW>
            end
            md(end+1, 1) = "";
        end

        md(end+1, 1) = sprintf( ...
            "Sweep ran %d point(s); %d succeeded, %d failed, %d cancelled.", ...
            N, sum(strcmp({Points.Status}, 'Success')), ...
            sum(strcmp({Points.Status}, 'Failed')), ...
            sum(strcmp({Points.Status}, 'Cancelled')));
        md(end+1, 1) = "";
    else
        md(end+1, 1) = "⚠️ **No successful sweep points to report on.**";
        md(end+1, 1) = "";
    end

    % ============== 2. Sweep Configuration ==============
    md(end+1, 1) = "## 2. Sweep Configuration";
    md(end+1, 1) = "";
    md(end+1, 1) = "| Parameter | Value |";
    md(end+1, 1) = "|-----------|-------|";
    md(end+1, 1) = sprintf("| Swept parameter | %s |", ParamLabel);
    md(end+1, 1) = sprintf("| Values | %s |", strjoin( ...
        arrayfun(@(x) sprintf('%g', x), SweepResult.Values(:)', ...
        'UniformOutput', false), ', '));

    if ~isempty(BaseExp) && isfield(BaseExp, 'ExperimentResult')
        C = BaseExp.ExperimentResult.Configuration;
        md(end+1, 1) = sprintf("| Algorithms | %s |", ...
            strjoin(C.Algorithms, ' + '));
        md(end+1, 1) = sprintf("| Runs per algorithm | %d |", C.NumberOfRuns);
        md(end+1, 1) = sprintf("| Cache mode | %s |", C.CacheMode);
        md(end+1, 1) = sprintf("| Population / Swarm | %d |", C.NS);
        md(end+1, 1) = sprintf("| Max Gen / Iter | %d |", C.MaxGen);
    end

    if ~isempty(BaseExp) && isfield(BaseExp, 'Settings')
        S = BaseExp.Settings;
        if isfield(S, 'GA')
            md(end+1, 1) = sprintf("| GA Pc | %.3f |", S.GA.Pc);
            md(end+1, 1) = sprintf("| GA Pm | %.3f |", S.GA.Pm);
        end
        if isfield(S, 'PSO')
            md(end+1, 1) = sprintf("| PSO w | %.3f |", S.PSO.w);
            md(end+1, 1) = sprintf("| PSO c1 | %.3f |", S.PSO.c1);
            md(end+1, 1) = sprintf("| PSO c2 | %.3f |", S.PSO.c2);
        end
    end
    md(end+1, 1) = "";

    if ~isempty(BaseExp) && isfield(BaseExp, 'ExperimentResult') && ...
            isfield(BaseExp.ExperimentResult, 'RunSeeds')
        md(end+1, 1) = "**Base experiment seed**: `" + ...
            string(sprintf('%.0f', ...
            BaseExp.ExperimentResult.Configuration.ExperimentSeed)) + "`";
        md(end+1, 1) = "";
        md(end+1, 1) = "Run seeds used across points:";
        md(end+1, 1) = "";
        md(end+1, 1) = "| Run | Seed |";
        md(end+1, 1) = "|-----|------|";
        for r = 1:numel(BaseExp.ExperimentResult.RunSeeds)
            md(end+1, 1) = sprintf("| %d | `%.0f` |", r, ...
                BaseExp.ExperimentResult.RunSeeds(r)); %#ok<AGROW>
        end
        md(end+1, 1) = "";
    end

    % ============== 3. Inputs & Integrity ==============
    md(end+1, 1) = "## 3. Input Files & Integrity";
    md(end+1, 1) = "";
    if ~isempty(BaseExp) && isfield(BaseExp, 'Environment')
        Env = BaseExp.Environment;
        md(end+1, 1) = "| File | SHA-256 |";
        md(end+1, 1) = "|------|---------|";
        md(end+1, 1) = "| `" + string(Env.InpFileName) + "` | `" + ...
            string(extractBefore(Env.InpFileHash, 17)) + "…` |";
        md(end+1, 1) = "| `" + string(Env.DFileName) + "` | `" + ...
            string(extractBefore(Env.DFileHash, 17)) + "…` |";
        md(end+1, 1) = "| `" + string(Env.CostFileName) + "` | `" + ...
            string(extractBefore(Env.CostFileHash, 17)) + "…` |";
        md(end+1, 1) = "";
        md(end+1, 1) = "Full inputs are in `inputs/`. Every sweep point " + ...
            "reused these exact inputs (verified by the common SHA-256).";
        md(end+1, 1) = "";
    else
        md(end+1, 1) = "_Inputs metadata unavailable._";
        md(end+1, 1) = "";
    end

    % ============== 4. Per-Point Results ==============
    md(end+1, 1) = "## 4. Per-Point Results";
    md(end+1, 1) = "";

    Headers = {ParamLabel, 'Status', 'Best Cost', 'Feasible', ...
        'Feasibility %', 'Mean Cost', 'Std Cost', 'Mean Time (s)', 'File'};
    Data = cell(N, numel(Headers));

    for k = 1:N
        P = Points(k);
        Data{k, 1} = sprintf('%g', P.Value);
        Data{k, 2} = P.Status;
        if strcmp(P.Status, 'Success')
            Data{k, 3} = sprintf('%.2f', P.BestScore);
            if P.BestFeasible, Data{k, 4} = 'Yes';
            else,               Data{k, 4} = 'No'; end
            Data{k, 5} = sprintf('%.1f', 100 * P.FeasibilityRate);
            Data{k, 6} = sprintf('%.2f', P.MeanCost);
            Data{k, 7} = sprintf('%.2f', P.StdCost);
            Data{k, 8} = sprintf('%.2f', P.MeanTime);
            [~, name, ext] = fileparts(P.WdsxPath);
            Data{k, 9} = [name ext];
        else
            Data{k, 3} = '—';
            Data{k, 4} = '—';
            Data{k, 5} = '—';
            Data{k, 6} = '—';
            Data{k, 7} = '—';
            Data{k, 8} = '—';
            Data{k, 9} = '—';
        end
    end

    md = [md; markdownTable(Headers, Data)];
    md(end+1, 1) = "";

    % ============== 5. Trends ==============
    md(end+1, 1) = "## 5. Trends";
    md(end+1, 1) = "";

    if ~isempty(candidates)
        Xv = [Points(candidates).Value];
        [minCost, locMin] = min([Points(candidates).BestScore]);
        bestVal = Xv(locMin);

        md(end+1, 1) = sprintf( ...
            "Best cost across sweep is **%.2f** at **%s = %g**.", ...
            minCost, ParamLabel, bestVal);

        if numel(candidates) >= 2
            if locMin == 1
                md(end+1, 1) = "- Increasing the parameter from the lowest " + ...
                    "value in the sweep increases the best cost.";
            elseif locMin == numel(candidates)
                md(end+1, 1) = "- Increasing the parameter toward the highest " + ...
                    "value in the sweep decreases the best cost.";
            else
                md(end+1, 1) = "- The optimum is interior; going lower " + ...
                    "or higher than the best value increases cost.";
            end
        end
        md(end+1, 1) = "";
    end

    md(end+1, 1) = "![Best Cost vs Parameter](figures/trend_best_cost.png)";
    md(end+1, 1) = "";
    md(end+1, 1) = "![Mean Cost vs Parameter](figures/trend_mean_cost.png)";
    md(end+1, 1) = "";
    md(end+1, 1) = "![Mean Time vs Parameter](figures/trend_time.png)";
    md(end+1, 1) = "";

    % ============== 6. Convergence Overlay ==============
    md(end+1, 1) = "## 6. Convergence Overlay";
    md(end+1, 1) = "";
    md(end+1, 1) = "Mean best-cost convergence of every point on the same axes:";
    md(end+1, 1) = "";
    md(end+1, 1) = "![Convergence Overlay](figures/convergence_overlay.png)";
    md(end+1, 1) = "";

    % ============== 7. Distribution Overlay ==============
    md(end+1, 1) = "## 7. Distribution Overlay";
    md(end+1, 1) = "";
    md(end+1, 1) = "Final cost distribution of feasible successful runs per point:";
    md(end+1, 1) = "";
    md(end+1, 1) = "![Distribution Overlay](figures/distribution_overlay.png)";
    md(end+1, 1) = "";

    % ============== 8. Data Files ==============
    md(end+1, 1) = "## 8. Data Files";
    md(end+1, 1) = "";
    md(end+1, 1) = "| File | Contents |";
    md(end+1, 1) = "|------|----------|";
    md(end+1, 1) = "| `data/sweep_summary.xlsx` | Sweep summary table |";
    md(end+1, 1) = "| `data/sweep_summary.csv` | Same, CSV |";
    md(end+1, 1) = "| `data/points_index.csv` | List of points with WDSX file names and sizes |";
    md(end+1, 1) = "| `data/all_points_convergence.csv` | Per-generation convergence for every point (long format) |";
    md(end+1, 1) = "| `data/sweep_manifest.txt` | Summary of sweep-level configuration |";
    md(end+1, 1) = "";

    % ============== Footer ==============
    md(end+1, 1) = "---";
    md(end+1, 1) = "";
    md(end+1, 1) = "_This report was generated automatically by " + ...
        "WDS Optimization Toolkit. Each sweep point's .wdsx snapshot is " + ...
        "the authoritative record; this report is a synthesis._";
end