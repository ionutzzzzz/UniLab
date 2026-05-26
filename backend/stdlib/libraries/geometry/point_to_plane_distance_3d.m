function d = point_to_plane_distance_3d(px, py, pz, a, b, c, d_plane)
    % POINT_TO_PLANE_DISTANCE_3D Distance from point to plane ax + by + cz + d = 0
    num = abs(a*px + b*py + c*pz + d_plane);
    den = sqrt(a^2 + b^2 + c^2);
    d = num / den;
end
