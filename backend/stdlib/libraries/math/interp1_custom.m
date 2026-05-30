function [v_interp] = interp1_custom(x, v, x_interp, method)
    % INTERP1_CUSTOM 1D data interpolation
    % [v_interp] = interp1_custom(x, v, x_interp, method)
    % methods: 'linear' (default), 'lagrange'
    
    if nargin < 4, method = 'linear'; end
    
    if strcmp(method, 'linear')
        v_interp = linear_interp(x, v, x_interp);
    elseif strcmp(method, 'lagrange')
        v_interp = lagrange_interp(x, v, x_interp);
    else
        disp(['Warning: Unknown method ', method, '. Falling back to linear.']);
        v_interp = linear_interp(x, v, x_interp);
    end
end
