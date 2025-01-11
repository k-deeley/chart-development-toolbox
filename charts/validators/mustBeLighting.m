function mustBeLighting( option )
%MUSTBELIGHTING Validate that the given input string, option, represents a 
%valid lighting option for a surface object.

s = matlab.graphics.primitive.Surface();
surfaceCleanup = onCleanup( @() delete( s ) );
lightingValues = set( s, "FaceLighting" );
mustBeMember( option, lightingValues )

end % mustBeLighting