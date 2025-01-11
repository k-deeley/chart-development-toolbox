function mustBeIncreasing( v )
%MUSTBEINCREASING Validate that the input vector, v, is increasing.

validateattributes( v, "double", "increasing" )

end % mustBeIncreasing