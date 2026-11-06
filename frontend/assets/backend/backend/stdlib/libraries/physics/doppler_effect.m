function f_obs = doppler_effect(f_src, v, v_obs, v_src)
    if nargin < 1, f_src = []; end
    if nargin < 2, v = []; end
    if nargin < 3, v_obs = []; end
    if nargin < 4, v_src = []; end
    f_obs = f_src * ((v + v_obs) / (v - v_src));
end