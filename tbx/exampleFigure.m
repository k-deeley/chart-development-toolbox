function f = exampleFigure( namedArgs )
%EXAMPLEFIGURE Create a custom figure for use in different chart examples
% This function creates a figure with a standard size for use across
% different chart examples. Any of the preset properties (Units, Position)
% may be overridden by passing name-value pairs to the function.

% Copyright 2018-2025 The MathWorks, Inc.

arguments ( Input )
    namedArgs.?matlab.ui.Figure
end % arguments ( Input )

arguments ( Output )
    f(1, 1) matlab.ui.Figure
end % arguments ( Output )

f = uifigure( "Units", "normalized", ...
    "Position", [0.30, 0.20, 0.40, 0.50] );
set( f, namedArgs )

end % exampleFigure