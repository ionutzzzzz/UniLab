function [curl] = curl_2d(Fx, Fy, dx, dy)
    % CURL_2D Numerical curl of a 2D vector field (z-component)
    % curl = dFy/dx - dFx/dy
    
    [dFxx, dFxy] = gradient_2d(Fx, dx, dy);
    [dFyx, dFyy] = gradient_2d(Fy, dx, dy);
    
    curl = dFyx - dFxy;
end
