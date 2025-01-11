function [G, nodeLabels] = kids2graph( graphicsObject, namedArgs )
%KIDS2GRAPH Construct a graph listing the descendants of the given graphics
%object.

arguments ( Input )
    graphicsObject(1, 1) {mustBeValidGraphics}
    namedArgs.ShowHiddenHandles(1, 1) matlab.lang.OnOffSwitchState = "off"
end % arguments ( Input )

arguments ( Output )
    G(1, 1) graph
    nodeLabels(:, 1) string
end % arguments ( Output )

% If requested, ensure that children are found even if their
% HandleVisibility is "off".
if namedArgs.ShowHiddenHandles
    root = groot();
    hiddenStatus = root.ShowHiddenHandles;
    root.ShowHiddenHandles = "on";
    rootCleanup = onCleanup( ...
        @() set( root, "ShowHiddenHandles", hiddenStatus ) );
end % if

% Initialize the node indices and object names.
startNodes = [];
endNodes = [];
nodeLabels = string( class( graphicsObject ) );
parentIdx = 1;
currentIdx = 1;

% Navigate the graphics hierarchy looking for children.
traverseChildren( graphicsObject, parentIdx )

% Prepare the node names for display. We use the last part of the 
% fully-qualified class name. Typically graphics objects are located in 
% nested packages with long names. For example, "matlab.ui.control.Button"
% will become "Button" after this step.
for nodeIdx = 1 : numel( nodeLabels )
    fragments = string( split( nodeLabels{nodeIdx}, "." ) );
    nodeLabels(nodeIdx) = fragments(end);
end % for

% Assemble the object graph.
G = graph( startNodes, endNodes );

    function traverseChildren( parentObject, parentIdx )
        %TRAVERSECHILDREN Traverse the children of the given parent
        %graphics object. This function is recursive.

        % Keep going until the parent object no longer has the Children
        % property.
        if isprop( parentObject, "Children" )

            % Extract the children of the current parent object.
            kids = parentObject.Children;

            % Loop over each child.
            for k = 1 : numel( kids )

                % Update the current child and index.
                currentKid = kids(k);
                currentIdx = currentIdx + 1;

                % Update the node names.
                nodeLabels(currentIdx) = string( class( currentKid ) );
                if nodeLabels(currentIdx) == ...
                        "matlab.ui.container.GridLayout"
                    nodeLabels(currentIdx) = ...
                        nodeLabels(currentIdx) + " (" + ...
                        num2str( numel( currentKid.RowHeight ) ) + ...
                        "-by-" + ...
                        num2str( numel( currentKid.ColumnWidth ) ) + ")";
                end % if

                % Update the node indices.
                startNodes(end+1, 1) = parentIdx; %#ok<*AGROW>
                endNodes(end+1, 1) = currentIdx;

                % Recurse into the current child.
                traverseChildren( currentKid, currentIdx )

            end % for

        end % if

    end % traverseChildren

end % kids2graph