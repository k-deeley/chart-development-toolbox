function folder = chartsDocRoot()
%CHARTSDOCROOT Folder containing the Chart Development Toolbox examples
%
% folder = chartsDocRoot() returns the full path to the folder containing
% the Chart Development Toolbox examples and documentation.
%
% Example:
% >> folder = chartsDocRoot()
% folder = 'C:\MATLAB\Chart Development Toolbox\chartsdoc'

% Copyright 2018-2024 The MathWorks, Inc.

folder = fileparts( mfilename( "fullpath" ) );

end % chartsRoot