function [eff_map] = ee_motor_efficiency_map(T_range, w_range, P_loss_func)
    % EE_MOTOR_EFFICIENCY_MAP Generates a motor efficiency map
    % T_range: torque vector, w_range: speed vector
    
    [T, W] = meshgrid(T_range, w_range);
    P_out = T .* W;
    
    % Example loss model: P_loss = k1*w + k2*T^2 + k3*w^2
    % In UniLab, we expect P_loss_func to be a handle or a result matrix
    if isnumeric(P_loss_func)
        P_loss = P_loss_func;
    else
        P_loss = unilab_call(P_loss_func, T, W);
    end
    
    eff_map = P_out ./ (P_out + P_loss);
    eff_map(P_out <= 0) = 0;
end
