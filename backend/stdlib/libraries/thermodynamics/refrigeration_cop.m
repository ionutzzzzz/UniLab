function cop = refrigeration_cop(Q_low, W_in)
    % REFRIGERATION_COP Coefficient of Performance for a refrigerator
    if nargin < 1, Q_low = []; end
    if nargin < 2, W_in = []; end
    cop = Q_low / W_in;
end
