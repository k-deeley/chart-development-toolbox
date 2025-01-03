function mustBeFontAngle( fontAngle )
%MUSTBEFONTANGLE Validate that the given string, fontAngle, represents a 
%valid font angle value for a text object.

t = matlab.graphics.primitive.Text();
textCleanup = onCleanup( @() delete( t ) );
fontAngleValues = set( t, "FontAngle" );
mustBeMember( fontAngle, fontAngleValues )

end % mustBeFontAngle

