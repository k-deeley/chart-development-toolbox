function mustBeFontWeight( fontWeight )
%MUSTBEFONTWEIGHT Validate that the given string, fontWeight, represents a
%valid font angle weight for a text object.

t = matlab.graphics.primitive.Text();
textCleanup = onCleanup( @() delete( t ) );
fontWeightValues = set( t, "FontWeight" );
mustBeMember( fontWeight, fontWeightValues )

end % mustBeFontWeight