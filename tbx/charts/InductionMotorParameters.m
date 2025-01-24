classdef InductionMotorParameters
    %INDUCTIONMOTORPARAMETERS Stores parameters for an induction motor.
    %
    % See also InductionMotorChart.

    % Copyright 2021-2025 The MathWorks, Inc.

    properties
        % Speed-torque coordinates of the normal operating region. This is
        % a rectangular region with vertex coordinates
        % [xmin, ymin; xmin, ymax; xmax, ymax; xmax, ymin].
        NormalRegion(4, 2) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the buffer region. The buffer region
        % comprises two distinct rectangular regions. The coordinates are
        % specified in the form [x1, x2, y1, y2], where [xi, yi] is the
        % 4-by-2 matrix containing the vertex coordinates of the ith patch,
        % for i = 1, 2.
        BufferRegion(4, 4) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the overload region. The overload
        % region comprises two distinct trapezoidal regions. The
        % coordinates are specified in the form [x1, x2, y1, y2], where
        % [xi, yi] is the 4-by-2 matrix containing the vertex coordinates
        % of the ith patch, for i = 1, 2.
        OverloadRegion(4, 4) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the axes bounds, in the form
        % [xmin, xmax, ymin, ymax].
        Bounds(1, 4) double {mustBeReal, mustBeFinite}
        % Speed-torque coordinates of the reduced curves, in the form of an
        % N-by-2 matrix [x, y]. The matrix may contain NaNs to separate
        % distinct curves.
        ReducedCurves(:, 2) double {mustBeReal}
        % Speed-torque coordinates of the rated curves, in the form of an
        % N-by-2 matrix [x, y]. The matrix may contains NaNs to separate
        % distinct curves.
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