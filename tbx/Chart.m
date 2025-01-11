classdef ( Abstract ) Chart < matlab.graphics.chartcontainer.ChartContainer
    %CHART Superclass for ChartContainer chart implementation.

    % Copyright 2024-2025 The MathWorks, Inc.

    methods

        function obj = Chart()
            %CHART Construct a Chart object.

            % Call the superclass constructor.
            f = figure( "Visible", "off" );
            figureCleanup = onCleanup( @() delete( f ) );
            obj@matlab.graphics.chartcontainer.ChartContainer( ...
                "Parent", f )
            obj.Parent = [];

        end % constructor

    end % methods

end % classdef