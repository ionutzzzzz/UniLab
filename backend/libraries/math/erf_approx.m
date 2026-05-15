function [y] = erf_approx(x)
    % ERF_APPROX Numerical approximation of the Error Function
    % Using the Abramowitz and Stegun approximation
    
    a1 =  0.254829592;
    a2 = -0.284496736;
    a3 =  1.421413741;
    a4 = -1.453152027;
    a5 =  1.061405429;
    p  =  0.3275911;

    sign_x = (x >= 0) - (x < 0);
    x = abs(x);

    t = 1.0 ./ (1.0 + p .* x);
    y = 1.0 - (((((a5 .* t + a4) .* t) + a3) .* t + a2) .* t + a1) .* t .* exp(-x .* x);
    y = sign_x .* y;
end
