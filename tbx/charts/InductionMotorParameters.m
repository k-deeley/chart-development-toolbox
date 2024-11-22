classdef InductionMotorParameters
    %INDUCTIONMOTORPARAMETERS Stores parameters for an induction motor.

    properties
        % Speed-torque coordinates of the normal operating region.
        NormalRegion(4, 2) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the buffer region.
        BufferRegion(4, 4) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the overload region.
        OverloadRegion(4, 4) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the bounds.
        Bounds(1, 4) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the reduced curves.
        ReducedCurves(:, 2) double {mustBeReal}
        % Speed-torque coordinates of the rated curves.
        RatedCurves(:, 2) double {mustBeReal}
    end % properties

    methods

        function obj = InductionMotorParameters( dataFolder )
            %INDUCTIONMOTORPARAMETERS Construct an InductionMotorParameters
            % object, given an optional data folder containing motor data.
            % This constructor assumes that the following data files are
            % available in the folder:
            %
            % * NormalRegion.csv
            % * BufferRegion.csv
            % * OverloadRegion.csv
            % * Bounds.csv
            % * ReducedCurves.csv
            % * RatedCurves.csv
            %
            % Alternatively, specify the motor parameters directly by
            % property assignment.

            arguments ( Input )
                dataFolder(:, 1) string {mustBeFolder} = ...
                    string.empty( 0, 1 )
            end % arguments ( Input )

            if ~isempty( dataFolder )
                obj.NormalRegion = readmatrix( fullfile( dataFolder, ...
                    "NormalRegion.csv" ) );
                obj.BufferRegion = readmatrix( fullfile( dataFolder, ...
                    "BufferRegion.csv" ) );
                obj.OverloadRegion = readmatrix( fullfile( dataFolder, ...
                    "OverloadRegion.csv" ) );
                obj.Bounds = readmatrix( fullfile( dataFolder, ...
                    "Bounds.csv" ) );
                obj.ReducedCurves = readmatrix( fullfile( dataFolder, ...
                    "ReducedCurves.csv" ) );
                obj.RatedCurves = readmatrix( fullfile( dataFolder, ...
                    "RatedCurves.csv" ) );
            end % if

        end % constructor

    end % methods

end % classdef