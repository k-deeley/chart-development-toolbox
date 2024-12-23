function varargout = chartCatalog()
%CHARTCATALOG Launch the chart catalog.
% 
% Launcher for the Chart Catalog application. Calling |chartCatalog| with an 
% output argument returns a reference to the application figure window.
%
% Copyright 2018-2022 The MathWorks, Inc.

% Launch the application.
CL = CatalogLauncher();

% Return the figure as an output argument, if this is requested.
if nargout > 0
    nargoutchk( 1, 1 )
    varargout{1} = CL.Figure;
end % if

end % chartCatalog