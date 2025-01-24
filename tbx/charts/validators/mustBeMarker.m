function mustBeMarker( marker )
%MUSTBEMARKER Validate that the given string, marker, represents a valid
%marker value for a line or scatter object.

p = matlab.graphics.chart.primitive.Line();
plotCleanup = onCleanup( @() delete( p ) );
markerValues = set( p, "Marker" );
mustBeMember( marker, markerValues )

end % mustBeMarker