function [R] = rot_matrix_3d(theta, axis)
    % ROT_MATRIX_3D 3D Rotation Matrix around 'x', 'y', or 'z'
    
    if nargin < 1, theta = []; end
    if nargin < 2, axis = []; end
    c = cos(theta);
    s = sin(theta);
    
    if strcmp(axis, 'x')
        R = [1, 0, 0; 0, c, -s; 0, s, c];
    elseif strcmp(axis, 'y')
        R = [c, 0, s; 0, 1, 0; -s, 0, c];
    else % 'z'
        R = [c, -s, 0; s, c, 0; 0, 0, 1];
    end
end
