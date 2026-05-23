function obj = setTurnover(obj, initial_weights, turnover_limit)
    % SETTURNOVER Adds turnover constraint
    
    obj.Constraints.InitialWeights = initial_weights;
    obj.Constraints.TurnoverLimit = turnover_limit;
end
