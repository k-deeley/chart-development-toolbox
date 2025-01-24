classdef ( Abstract ) Component < matlab.ui.componentcontainer.ComponentContainer
    %COMPONENT Superclass for ComponentContainer chart implementation.

    % Copyright 2024-2025 The MathWorks, Inc.

    methods

        function obj = Component()
            %COMPONENT Construct a Component object.

            % Call the superclass constructor.
            obj@matlab.ui.componentcontainer.ComponentContainer( ...
                "Parent", [], ...
                "Units", "normalized", ...
                "Position", [0, 0, 1, 1] )

        end % constructor

    end % methods

end % classdef