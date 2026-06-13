function v = wave_speed(f, lambda)
    % WAVE_SPEED Calculate wave speed
    % v = f * lambda
    if nargin < 1, f = []; end
    if nargin < 2, lambda = []; end
    v = f * lambda;
end
