function mustBeValidGraphics( gobj )
%MUSTBEVALIDGRAPHICS Validate that the input, gobj, is a valid graphics
%object.

assert( isgraphics( gobj ) && isvalid( gobj ), ...
    "GraphicsHierarchyChart:InvalidGraphicsObject", ...
    "The input must be a valid graphics object." )

end % mustBeValidGraphics