function plotHierarchy( graphicsObject, includeHidden )
%PLOTHIERARCHY Visualize the graphics hierarchy under the given parent 
%graphics object using a MATLAB graph.
%If includeHidden is true, then the hierarchy also includes children with 
%their HandleVisibility set to "off".

arguments
    graphicsObject(1, 1) {mustBeValidScalarGraphics( graphicsObject )} = groot()
    includeHidden(1, 1) logical = false
end % arguments

% If requested, ensure that children are found even if their
% HandleVisibility is "off".
if includeHidden
    gr = groot();
    hiddenStatus = gr.ShowHiddenHandles;
    gr.ShowHiddenHandles = "on";
    oc = onCleanup( @() set( gr, "ShowHiddenHandles", hiddenStatus ) );
end % if

% Initialize the node indices and object names.
startNodes = [];
endNodes = [];
nodeNames = {class( graphicsObject )};
parentIdx = 1;
currentIdx = 1;

% Navigate the graphics hierarchy looking for children.
findChildren( graphicsObject, parentIdx )

% Prepare the node names for display. We just use the last part of the
% fully-qualified class name (typically graphics objects are in nested
% packages with long names).
for nodeIdx = 1 : numel( nodeNames )
    fragments = split( nodeNames{nodeIdx}, "." );
    nodeNames{nodeIdx} = fragments(end);
end % for
%nodeNames = regexp( nodeNames, "(?<=[.])[A-Za-z0-9()-\s]*$", "match" );
%nodeNames = [nodeNames{:}];

% Create the object graph.
G = graph( startNodes, endNodes );

% Visualize the graph.
f = figure;
ax = axes( "Parent", f );
p = plot( G, "Parent", ax, ...
    "MarkerSize", 8, ...
    "NodeColor", "r", ...
    "NodeLabel", {}, ...
    "LineWidth", 2.5 );
axis( ax, "off" )
xl = ax.XLim;
offset = 0.005 * diff( xl );
text( ax, p.XData + offset, p.YData, nodeNames, ...
    "FontSize", 14, ...
    "FontWeight", "bold" )

    function findChildren( parent, parentIdx )

        % Keep going until the object no longer has the Children property.
        if isprop( parent, "Children" )
            c = parent.Children;
            for k = 1:numel(c)
                currentChild = c(k);
                currentIdx = currentIdx + 1;
                % Update the node names.
                nodeNames{currentIdx} = class( currentChild );
                if nodeNames{currentIdx} == ...
                        "matlab.ui.container.GridLayout"
                    nodeNames{currentIdx} = ...
                        [nodeNames{currentIdx}, ...
                        ' (', ...
                        num2str( numel( currentChild.RowHeight ) ), ...
                        '-by-', ...
                        num2str( numel( currentChild.ColumnWidth ) ), ...
                        ')'];
                end % if
                % Update the node indices.
                startNodes(end+1, 1) = parentIdx; %#ok<*AGROW>
                endNodes(end+1, 1) = currentIdx;
                % Recurse into the current child.
                findChildren( currentChild, currentIdx )
            end % for
        end % if

    end % findChildren

end % plotHierarchy

function mustBeValidScalarGraphics( gobj )

assert( isgraphics( gobj ) && isscalar( gobj) && isvalid( gobj ), ...
    "plotHierarchy:InvalidGraphicsObject", ...
    "The input must be a valid scalar graphics object." )

end % mustBeValidScalarGraphics
