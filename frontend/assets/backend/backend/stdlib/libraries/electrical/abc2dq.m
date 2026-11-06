function [dq0] = abc2dq(abc, theta)
    % ABC2DQ Performs Park transformation (abc to dq0)
    % dq0 = abc2dq(abc, theta)
    % abc: [a, b, c] vector or Nx3 matrix
    % theta: rotation angle in radians
    
    if nargin < 1, abc = []; end
    if nargin < 2, theta = []; end
    if size(abc, 2) ~= 3
        abc = abc';
    end
    
    a = abc(:, 1);
    b = abc(:, 2);
    c = abc(:, 3);
    
    d = (2/3) * (a .* cos(theta) + b .* cos(theta - 2*pi()/3) + c .* cos(theta + 2*pi()/3));
    q = -(2/3) * (a .* sin(theta) + b .* sin(theta - 2*pi()/3) + c .* sin(theta + 2*pi()/3));
    z = (1/3) * (a + b + c);
    
    dq0 = [d, q, z];
end
