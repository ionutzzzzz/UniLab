function [u, state] = pid_controller(setpoint, process_val, state, Kp, Ki, Kd, dt)
    % PID_CONTROLLER A simple PID controller implementation
    % [u, state] = pid_controller(setpoint, process_val, state, Kp, Ki, Kd, dt)
    % state is a struct with .integral and .prev_error
    
    error = setpoint - process_val;
    
    % Proportional term
    P = Kp * error;
    
    % Integral term
    state.integral = state.integral + error * dt;
    I = Ki * state.integral;
    
    % Derivative term
    derivative = (error - state.prev_error) / dt;
    D = Kd * derivative;
    
    u = P + I + D;
    state.prev_error = error;
end
