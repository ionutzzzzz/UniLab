function [abc] = dq2abc(dq0, theta)
    % DQ2ABC Performs inverse Park transformation (dq0 to abc)
    % abc = dq2abc(dq0, theta)
    
    if nargin < 1, dq0 = []; end
    if nargin < 2, theta = []; end
    if size(dq0, 2) ~= 3
        dq0 = dq0';
    end
    
    d = dq0(:, 1);
    q = dq0(:, 2);
    z = dq0(:, 3);
    
    a = d .* cos(theta) - q .* sin(theta) + z;
    b = d .* cos(theta - 2*pi()/3) - q .* sin(theta - 2*pi()/3) + z;
    c = d .* cos(theta + 2*pi()/3) - q .* sin(theta + 2*pi()/3) + z;
    
    abc = [a, b, c];
end
