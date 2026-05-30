function mod_d = modified_duration(mac_d, yield_rate, periods_per_year)
    mod_d = mac_d / (1 + yield_rate / periods_per_year);
end