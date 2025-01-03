function mustBeLegendLocation( option )
%MUSTBELEGENDLOCATION Validate that the given input string, option,
%represents a valid location for a legend object.

lg = matlab.graphics.illustration.Legend();
legendCleanup = onCleanup( @() delete( lg ) );
locationValues = set( lg, "Location" );
mustBeMember( option, locationValues )

end % mustBeLegendLocation