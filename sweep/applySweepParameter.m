function [Config, Options, Settings, Problem] = applySweepParameter( ...
    Config, Options, Settings, Problem, ParameterName, Value)
%APPLYSWEEPPARAMETER Override one parameter with a given value.
%
%   Returns the modified Config, Options, Settings, and Problem. Problem
%   is passed through unchanged for algorithm/size parameters, and only
%   mutated for constraint sweep parameters (Pmin, Vmax).

    switch ParameterName
        case 'GA_Pc'
            Config.GA.Pc     = Value;
            Settings.GA.Pc   = Value;

        case 'GA_Pm'
            Config.GA.Pm     = Value;
            Settings.GA.Pm   = Value;

        case 'PSO_w'
            Config.PSO.w     = Value;
            Settings.PSO.w   = Value;

        case 'PSO_c1'
            Config.PSO.c1    = Value;
            Settings.PSO.c1  = Value;

        case 'PSO_c2'
            Config.PSO.c2    = Value;
            Settings.PSO.c2  = Value;

        case 'NS'
            Config.NS        = Value;

        case 'MaxGen'
            Config.MaxGen    = Value;

        case 'NumberOfRuns'
            Options.NumberOfRuns  = Value;
            Settings.NumberOfRuns = Value;

        case 'ExperimentSeed'
            Options.ExperimentSeed  = Value;
            Settings.ExperimentSeed = Value;

        case 'Pmin'
            Problem.Pmin = Value;

        case 'Vmax'
            Problem.Vmax = Value;

        otherwise
            error('applySweepParameter:Unknown', ...
                'Unknown sweep parameter: %s', ParameterName);
    end
end