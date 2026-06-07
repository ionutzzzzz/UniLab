function curve = IRFunctionCurve(type, params)
    % IRFUNCTIONCURVE Returns a struct for interest rate curves
    curve.Type = type;
    curve.Params = params;
    % Mock function returning a simple linear interpolation based on params if provided
    curve.Function = @(t) 0.02 + 0.001 * t; 
end
