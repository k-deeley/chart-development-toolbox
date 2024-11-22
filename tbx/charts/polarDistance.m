function d = polarDistance( point, pointArray )
%POLARDISTANCE Compute the squared distances between points represented in
%polar coordinates (theta, rho), where the angular coordinate theta is
%measured in radians.

% Extract the (theta, rho) coordinates.
theta1 = point(1);
theta2 = pointArray(:, 1);
rho1   = abs( point(2) );
rho2   = abs( pointArray(:, 2) );

% Evaluate the squared distances.
d = rho1 ^ 2 + rho2 .^ 2 - 2 * rho1 * rho2 .* cos( theta1 - theta2 );

end % polarDistance