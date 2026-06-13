function [R] = rot_matrix_2d(theta)
    % ROT_MATRIX_2D 2D Rotation Matrix
    
    if nargin < 1, theta = []; end
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
end
