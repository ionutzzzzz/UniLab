function [trans_data, lambda] = boxcox(data, lambda)
    % BOXCOX Box-Cox transformation
    
    if nargin < 2
        lambda = 0.5;
    end
    
    if lambda == 0
        trans_data = log(data);
    else
        trans_data = (data.^lambda - 1) / lambda;
    end
end
