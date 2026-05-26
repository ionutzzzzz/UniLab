function [R] = rot_matrix_2d(theta)
    % ROT_MATRIX_2D 2D Rotation Matrix
    
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
end
