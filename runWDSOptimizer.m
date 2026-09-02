function app = runWDSOptimizer()
%RUNWDSOPTIMIZER Initialize and launch the WDS Optimizer application.
%
% Usage:
%   runWDSOptimizer
%
% The function automatically:
%   1. Configures the WDS Optimizer environment.
%   2. Initializes the bundled EPANET-MATLAB Toolkit.
%   3. Launches the WDS Optimizer GUI.

    setupWDSOptimizer();

    app = WDS_Optimizer_App();

end