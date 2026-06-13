function theta_c = total_internal_reflection_angle(n1, n2)
    % TOTAL_INTERNAL_REFLECTION_ANGLE Calculate critical angle for TIR
    % theta_c = asin(n2 / n1)
    if nargin < 1, n1 = []; end
    if nargin < 2, n2 = []; end
    if n2 > n1
        error('n1 must be greater than n2 for TIR');
    end
    theta_c = asin(n2 / n1);
end
