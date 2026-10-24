function [Config, Options, Settings] = applySweepParameter( ...
    Config, Options, Settings, ParameterName, Value)
%APPLYSWEEPPARAMETER Override one parameter with a given value.

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
            % Not part of Settings

        case 'MaxGen'
            Config.MaxGen    = Value;
            % Not part of Settings

        case 'NumberOfRuns'
            Options.NumberOfRuns  = Value;
            Settings.NumberOfRuns = Value;

        case 'ExperimentSeed'
            Options.ExperimentSeed  = Value;
            Settings.ExperimentSeed = Value;

        otherwise
            error('applySweepParameter:Unknown', ...
                'Unknown sweep parameter: %s', ParameterName);
    end
end