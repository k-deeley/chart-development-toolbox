function mustBeLineStyle( style )
%MUSTBELINESTYLE Validate that the given string, style, represents a valid
%line style value for a line object.

p = matlab.graphics.chart.primitive.Line();
plotCleanup = onCleanup( @() delete( p ) );
lineStyleValues = set( p, "LineStyle" );
mustBeMember( style, lineStyleValues )

end % mustBeLineStyle