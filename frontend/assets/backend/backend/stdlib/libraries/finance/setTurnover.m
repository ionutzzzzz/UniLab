function obj = setTurnover(obj, initial_weights, turnover_limit)
    % SETTURNOVER Adds turnover constraint
    
    if nargin < 1, obj = []; end
    if nargin < 2, initial_weights = []; end
    if nargin < 3, turnover_limit = []; end
    obj.Constraints.InitialWeights = initial_weights;
    obj.Constraints.TurnoverLimit = turnover_limit;
end
