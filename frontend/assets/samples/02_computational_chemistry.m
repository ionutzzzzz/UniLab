% 02_computational_chemistry.m
% UniLab Computational Chemistry: Reaction Kinetics & Thermodynamics

clear all;
close all;
clc;

disp('🧪 UniLab Computational Chemistry Lab');
disp('======================================');

%% 1. Enzyme Kinetics (Michaelis-Menten)
disp('--- 1. Michaelis-Menten Enzyme Kinetics ---');
% V = Vmax * [S] / (Km + [S])
Vmax = 100.0; Km_const = 5.0;
S_subs = linspace(0, 50, 100);
V_rate = Vmax * S_subs ./ (Km_const + S_subs);

figure;
subplot(1, 2, 1);
plot(S_subs, V_rate, 'b-', 'LineWidth', 2);
title('Michaelis-Menten Kinetics');
xlabel('[S] (substrate)'); ylabel('V (velocity)');
grid on;

subplot(1, 2, 2);
% skip first point to avoid divide by zero
inv_S = 1.0 ./ S_subs(2:end);
inv_V = 1.0 ./ V_rate(2:end);
plot(inv_S, inv_V, 'ro', 'MarkerSize', 8);
title('Lineweaver-Burk Plot');
xlabel('1/[S]'); ylabel('1/V');
grid on;

%% 2. Consecutive Reaction Kinetics (A -> B -> C)
disp(' ');
disp('--- 2. Consecutive Reaction Kinetics (A -> B -> C) ---');
% Using ODE solver
k1_rate = 0.5; k2_rate = 0.2;
y_init = [1.0, 0.0, 0.0]; % Row vector for state

function drdt = reaction_rates(t_val, r_state, k1, k2)
    % r_state is a vector
    A_conc = r_state(1); B_conc = r_state(2); C_conc = r_state(3);
    dA = -k1 * A_conc;
    dB = k1 * A_conc - k2 * B_conc;
    dC = k2 * B_conc;
    drdt = [dA, dB, dC]; % Return row vector
end

[T_vec, Y_mat] = ode45_custom(@(t, y) reaction_rates(t, y, k1_rate, k2_rate), [0, 20], y_init);

figure;
plot(T_vec, Y_mat(:, 1), 'r-', 'LineWidth', 2); hold on;
plot(T_vec, Y_mat(:, 2), 'g-', 'LineWidth', 2);
plot(T_vec, Y_mat(:, 3), 'b-', 'LineWidth', 2);
legend('Component A', 'Component B', 'Component C');
title('Reaction Kinetics: A \rightarrow B \rightarrow C');
xlabel('Time (s)'); ylabel('Concentration');
grid on;
hold off;

%% 3. Molecular Dynamics (Simple Lennard-Jones)
disp(' ');
disp('--- 3. Molecular Dynamics (Lennard-Jones Potential) ---');

function s_nxt = lj_step(s_cur, p_par)
    s_nxt = s_cur;
    dt_step = 0.05;
    r_val = s_cur.r; v_val = s_cur.v;
    f_force = 48.0 * p_par.eps * (p_par.sigma^12 / r_val^13 - 0.5 * p_par.sigma^6 / r_val^7);
    v_val = v_val + f_force * dt_step;
    s_nxt.r = r_val + v_val * dt_step;
    s_nxt.v = v_val;
    s_nxt.h = [s_cur.h; s_nxt.r];
end

function lj_draw(ax_obj, s_dyn)
    plot(ax_obj, s_dyn.h, 'b-');
    title(ax_obj, 'Atomic Distance (Lennard-Jones)');
    xlabel(ax_obj, 'Step'); ylabel(ax_obj, 'Distance');
end

% Simulating two atoms interaction
simulate('algorithm', 'step', @lj_step, 'draw', @lj_draw, 'state', struct('r', 2.0, 'v', 0.0, 'h', []), 'eps', 1.0, 'sigma', 1.0);

disp('Computational Chemistry Lab Complete.');
