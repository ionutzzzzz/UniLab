function theta_B = brewster_angle(n1, n2)
    % BREWSTER_ANGLE Calculate Brewster's angle
    % theta_B = atan(n2 / n1)
    if nargin < 1, n1 = []; end
    if nargin < 2, n2 = []; end
    theta_B = atan(n2 / n1);
end
