function t = irtimes(dates, start_date, convention)
    % IRTIMES Day count calculations (simple implementation)
    % convention: '30/360', 'ACT/360', 'ACT/365', 'ACT/ACT'
    if nargin < 1, dates = []; end
    if nargin < 2, start_date = []; end
    if nargin < 3, convention = 'ACT/365'; end
    
    % Simple mock implementation assuming dates are in days from a reference
    diff_days = dates - start_date;
    
    switch upper(convention)
        case '30/360'
            t = diff_days / 360; 
        case 'ACT/360'
            t = diff_days / 360;
        case 'ACT/365'
            t = diff_days / 365;
        case 'ACT/ACT'
            t = diff_days / 365.25;
        otherwise
            t = diff_days / 365;
    end
end
