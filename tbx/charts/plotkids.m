function varargout = plotkids( graphicsObject, namedArgs )
%PLOTKIDS Visualize the graphics hierarchy under the given parent
%graphics object. If "ShowHiddenHandles" is true, then the hierarchy also
%includes children with their HandleVisibility set to "off".

arguments ( Input )
    graphicsObject(1, 1) {mustBeValidGraphics}
    namedArgs.?GraphicsHierarchyChart
end % arguments ( Input )

% Validate the number of outputs.
nargoutchk( 0, 1 )

% Auto-parent if needed.
if ~isfield( namedArgs, "Parent" )
    namedArgs.Parent = gcf();
end % if

% Create the chart.
namedArgs = namedargs2cell( namedArgs );
GHC = GraphicsHierarchyChart( "RootObject", graphicsObject, namedArgs{:} );

% Return the chart if required.
if nargout == 1
    varargout{1} = GHC;
end % if

end % plotKids