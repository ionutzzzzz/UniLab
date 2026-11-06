function [pulses] = svpwm(v_alpha, v_beta, v_dc, fs)
    % SVPWM Space Vector Pulse Width Modulation
    % Simplified implementation returning duty cycles for three phases
    
    if nargin < 1, v_alpha = []; end
    if nargin < 2, v_beta = []; end
    if nargin < 3, v_dc = []; end
    if nargin < 4, fs = []; end
    v_ref = sqrt(v_alpha.^2 + v_beta.^2);
    theta = atan2(v_beta, v_alpha);
    % Wrap theta to 0-2pi
    theta(theta < 0) = theta(theta < 0) + 2*pi();
    
    sector = floor(theta / (pi()/3)) + 1;
    theta_rel = mod(theta, pi()/3);
    
    % Modulation index
    m = sqrt(3) * v_ref / v_dc;
    
    t1 = m .* sin(pi()/3 - theta_rel);
    t2 = m .* sin(theta_rel);
    t0 = 1 - t1 - t2;
    
    % Calculate duty cycles based on sector
    da = zeros(size(theta));
    db = zeros(size(theta));
    dc = zeros(size(theta));
    
    for i = 1:length(sector)
        s = sector(i);
        if s == 1
            da(i) = t1(i) + t2(i) + t0(i)/2;
            db(i) = t2(i) + t0(i)/2;
            dc(i) = t0(i)/2;
        elseif s == 2
            da(i) = t1(i) + t0(i)/2;
            db(i) = t1(i) + t2(i) + t0(i)/2;
            dc(i) = t0(i)/2;
        elseif s == 3
            da(i) = t0(i)/2;
            db(i) = t1(i) + t2(i) + t0(i)/2;
            dc(i) = t2(i) + t0(i)/2;
        elseif s == 4
            da(i) = t0(i)/2;
            db(i) = t1(i) + t0(i)/2;
            dc(i) = t1(i) + t2(i) + t0(i)/2;
        elseif s == 5
            da(i) = t2(i) + t0(i)/2;
            db(i) = t0(i)/2;
            dc(i) = t1(i) + t2(i) + t0(i)/2;
        else % sector 6
            da(i) = t1(i) + t2(i) + t0(i)/2;
            db(i) = t0(i)/2;
            dc(i) = t1(i) + t0(i)/2;
        end
    end
    
    pulses = [da, db, dc];
end
