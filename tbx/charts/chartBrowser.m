function varargout = chartBrowser()
%CHARTBROWSER Launch the Chart Browser application.
% 
% Launcher for the Chart Browser application. Calling |chartBrowser| with 
% an output argument returns a reference to the application.

% Copyright 2018-2025 The MathWorks, Inc.

% Check the number of output arguments.
nargoutchk( 0, 1 )

% Launch the application.
CBL = ChartBrowserLauncher();

% Return the app as output, if requested.
if nargout == 1
    varargout{1} = CBL.App;
end % if

end % chartBrowser