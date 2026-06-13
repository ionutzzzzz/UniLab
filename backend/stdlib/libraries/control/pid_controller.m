function [u, state] = pid_controller(setpoint, process_val, state, Kp, Ki, Kd, dt)
    % PID_CONTROLLER A simple PID controller implementation
    % [u, state] = pid_controller(setpoint, process_val, state, Kp, Ki, Kd, dt)
    % state is a struct with .integral and .prev_error
    
    if nargin < 1, setpoint = []; end
    if nargin < 2, process_val = []; end
    if nargin < 3, state = []; end
    if nargin < 4, Kp = []; end
    if nargin < 5, Ki = []; end
    if nargin < 6, Kd = []; end
    if nargin < 7, dt = []; end
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
