function mod_d = modified_duration(mac_d, yield_rate, periods_per_year)
    if nargin < 1, mac_d = []; end
    if nargin < 2, yield_rate = []; end
    if nargin < 3, periods_per_year = []; end
    mod_d = mac_d / (1 + yield_rate / periods_per_year);
end