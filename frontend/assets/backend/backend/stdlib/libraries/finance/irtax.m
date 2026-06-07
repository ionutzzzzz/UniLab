function output = irtax(yields, tax_rate)
    % IRTAX Simple implied tax rate calculation or after-tax yield
    % If tax_rate is provided, returns after-tax yields.
    % If two yields are provided (taxable, tax_exempt), returns implied tax rate.
    
    if nargin == 2
        output = yields .* (1 - tax_rate);
    else
        % Assume yields is [taxable, tax_exempt]
        if numel(yields) == 2
            output = 1 - (yields(2) / yields(1));
        else
            output = yields; % Default
        end
    end
end
