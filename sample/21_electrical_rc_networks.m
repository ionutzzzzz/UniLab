% 21_electrical_rc_networks.m
% Demonstrates electrical circuit equivalent calculations and power

disp('⚡ UniLab Electrical Networks');
disp('=============================');

disp('--- 1. Equivalent Circuit Analysis ---');
% A circuit with 3 parallel resistors in series with a complex capacitor bank
R_arr = [1000, 2200, 3300]; % Ohms
C_arr = [10e-6, 47e-6]; % Farads

Req_parallel = resistors_in_parallel(R_arr);
Ceq_series = capacitors_in_series(C_arr);

fprintf('Equivalent Parallel Resistance: %.2f Ohms
', Req_parallel);
fprintf('Equivalent Series Capacitance: %.2e Farads
', Ceq_series);

disp('--- 2. Transient Characteristics ---');
tau = rc_time_constant(Req_parallel, Ceq_series);
fprintf('RC Time Constant (tau): %.4f seconds
', tau);
fprintf('Time to fully charge (~5 tau): %.4f seconds
', 5 * tau);

disp('--- 3. Power Dissipation ---');
Voltage_supply = 24.0;
I_steady_state = Voltage_supply / Req_parallel; % assuming capacitors act as open circuit in DC
P_dissipated = electrical_power_res(I_steady_state, Req_parallel);
fprintf('Steady-state Power Dissipated by resistors: %.2f Watts
', P_dissipated);
