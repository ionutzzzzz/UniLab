function ess = steady_state_error_calc(G, type, input_type)
    % STEADY_STATE_ERROR_CALC Calculate steady-state error
    % input_type: 'step', 'ramp', 'parabola'
    
    if nargin < 1, G = []; end
    if nargin < 2, type = []; end
    if nargin < 3, input_type = []; end
    if strcmp(input_type, 'step')
        Kp = limit_transfer_function(G, 0);
        ess = 1 / (1 + Kp);
    elseif strcmp(input_type, 'ramp')
        Kv = limit_transfer_function(multiply_by_s(G), 0);
        ess = 1 / Kv;
    else
        Ka = limit_transfer_function(multiply_by_s_squared(G), 0);
        ess = 1 / Ka;
    end
end

function val = limit_transfer_function(G, s_val)
    % Simplified limit evaluation for polynomial TF
    if nargin < 1, G = []; end
    if nargin < 2, s_val = []; end
    val = polyval(G.num, s_val) / polyval(G.den, s_val);
end
