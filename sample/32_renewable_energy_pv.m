% 32_renewable_energy_pv.m
% UniLab Renewable Energy: Solar PV Modeling & MPPT Tracking

clear all;
clc;

disp('☀️ UniLab Renewable Energy Systems');
disp('===================================');

%% 1. Solar Cell I-V Characteristics
disp('--- 1. Single-Diode PV Cell Modeling ---');

function I = pv_current(V, G, T)
    % Single-diode model: I = Iph - Io*(exp(qV/nkT)-1)
    q = 1.602e-19; k = 1.38e-23;
    Iph = 5.0 * (G / 1000); % Photocurrent proportional to irradiance
    Io = 1e-9; % Saturation current
    n = 1.3; % Ideality factor
    Vt = (n * k * T) / q;
    
    I = Iph - Io * (exp(V / Vt) - 1);
    % Clamp negative current
    I(I < 0) = 0;
end

V_vec = linspace(0, 0.7, 100);
Irradiance = [400, 700, 1000]; % W/m^2
Temp = 298; % 25 deg C

figure;
subplot(1, 2, 1);
hold on;
for i = 1:3
    I_vals = pv_current(V_vec, Irradiance(i), Temp);
    plot(V_vec, I_vals, 'LineWidth', 2);
end
title('Solar Cell I-V Curve');
xlabel('Voltage (V)'); ylabel('Current (A)');
legend('400 W/m^2', '700 W/m^2', '1000 W/m^2');
grid on;

subplot(1, 2, 2);
hold on;
for i = 1:3
    I_vals = pv_current(V_vec, Irradiance(i), Temp);
    P_vals = V_vec .* I_vals;
    plot(V_vec, P_vals, 'LineWidth', 2);
end
title('Solar Cell P-V Curve');
xlabel('Voltage (V)'); ylabel('Power (W)');
grid on;

%% 2. Maximum Power Point Tracking (MPPT)
disp('--- 2. Perturb & Observe (P&O) MPPT Algorithm ---');

function s_n = mppt_step(s_c, p_p)
    s_n = s_c;
    % Get current power
    I = pv_current(s_c.V, s_c.G, 298);
    P = s_c.V * I;
    
    % P&O Logic
    dP = P - s_c.P_prev;
    dV = s_c.V - s_c.V_prev;
    
    step_size = 0.005;
    if dP > 0
        if dV > 0, s_n.V = s_c.V + step_size;
        else s_n.V = s_c.V - step_size;
        end
    else
        if dV > 0, s_n.V = s_c.V - step_size;
        else s_n.V = s_c.V + step_size;
        end
    end
    
    % Constrain V
    if s_n.V < 0, s_n.V = 0; end
    if s_n.V > 0.6, s_n.V = 0.6; end
    
    s_n.V_prev = s_c.V;
    s_n.P_prev = P;
    s_n.h = [s_c.h; [s_n.V, P]];
    if size(s_n.h, 1) > 200, s_n.h = s_n.h(end-199:end, :); end
    
    % Randomly change irradiance to test tracking
    if rand() < 0.02, s_n.G = 400 + rand() * 600; end
end

function mppt_draw(ax, s)
    % Background curve for current G
    V_bg = linspace(0, 0.7, 50);
    P_bg = V_bg .* pv_current(V_bg, s.G, 298);
    
    plot(ax, V_bg, P_bg, 'r--', 'LineWidth', 1); hold(ax, 'on');
    plot(ax, s.h(:, 1), s.h(:, 2), 'b-', 'LineWidth', 2);
    plot(ax, s.V, s.P_prev, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    title(ax, ['MPPT Tracking (Irradiance: ', num2str(round(s.G)), ' W/m^2)']);
    xlabel(ax, 'Voltage (V)'); ylabel(ax, 'Power (W)');
    grid(ax, 'on'); hold(ax, 'off');
end

st_pv = struct('V', 0.1, 'V_prev', 0.05, 'P_prev', 0, 'G', 800, 'h', []);
simulate('algorithm', 'step', @mppt_step, 'draw', @mppt_draw, 'state', st_pv);

disp('Renewable Energy Session Complete.');
