function v = frustum_volume(h, r1, r2)
    % FRUSTUM_VOLUME Volume of a conical frustum
    v = (1/3) * pi() * h * (r1^2 + r1*r2 + r2^2);
end
