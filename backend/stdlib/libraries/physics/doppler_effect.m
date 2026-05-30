function f_obs = doppler_effect(f_src, v, v_obs, v_src)
    f_obs = f_src * ((v + v_obs) / (v - v_src));
end