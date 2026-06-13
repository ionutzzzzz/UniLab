function theta2 = snells_law(n1, theta1, n2)
    if nargin < 1, n1 = []; end
    if nargin < 2, theta1 = []; end
    if nargin < 3, n2 = []; end
    theta2 = asin((n1 / n2) * sin(theta1));
end