function folder = chartsRoot()
%CHARTSROOT Folder containing the Chart Development Toolbox code
%
% folder = chartsRoot() returns the full path to the folder containing
% the Chart Development Toolbox code.
%
% Example:
% >> folder = chartsRoot()
% folder = 'C:\MATLAB\Chart Development Toolbox\charts'

% Copyright 2018-2024 The MathWorks, Inc.

folder = fileparts( mfilename( "fullpath" ) );

end % chartsRoot