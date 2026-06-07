% 05_epidemiology_seir.m
% UniLab Epidemiology: Disease Modeling (SEIR Model)

clear all;
close all;
clc;

disp('🦠 UniLab Epidemiology Lab');
disp('===========================');

%% 1. SEIR Model Simulation
disp('--- 1. SEIR Dynamic Modeling ---');
N_p = 1000.0; b_v = 0.3; s_v = 0.1; g_v = 0.1;
y_i = [999.0, 1.0, 0.0, 0.0];

function drdt = seir_model(t_v, r_s, beta, sigma, gamma, N)
    S = r_s(1); E = r_s(2); I = r_s(3); R = r_s(4);
    dS = -beta * S * I / N;
    dE = beta * S * I / N - sigma * E;
    dI = sigma * E - gamma * I;
    dR = gamma * I;
    drdt = [dS, dE, dI, dR];
end

[T_v, Y_m] = ode45_custom(@(t, y) seir_model(t, y, b_v, s_v, g_v, N_p), [0, 150], y_i);

figure;
plot(T_v, Y_m(:, 1), 'b-', 'LineWidth', 2); hold on;
plot(T_v, Y_m(:, 2), 'm-', 'LineWidth', 2);
plot(T_v, Y_m(:, 3), 'r-', 'LineWidth', 2);
plot(T_v, Y_m(:, 4), 'g-', 'LineWidth', 2);
legend('Susceptible', 'Exposed', 'Infectious', 'Recovered');
title('SEIR Model Outbreak Dynamics');
grid on; hold off;

%% 2. Interactive Spreading Simulator
disp(' ');
disp('--- 2. Stochastic Grid Spreading ---');

function s_n = spread_step(s_c, p_p)
    s_n = s_c;
    Grid = s_c.grid;
    [R, C] = size(Grid);
    nG = Grid;
    for i = 1:R
        for j = 1:C
            if Grid(i, j) == 1
                for di = -1:1
                    for dj = -1:1
                        ni = i + di; nj = j + dj;
                        if ni > 0 && ni <= R && nj > 0 && nj <= C
                            if Grid(ni, nj) == 0 && rand() < p_p.prob
                                nG(ni, nj) = 1;
                            end
                        end
                    end
                end
                if rand() < p_p.recovery_rate, nG(i, j) = 2; end
            end
        end
    end
    s_n.grid = nG;
end

function spread_draw(ax_o, s_d)
    imagesc(ax_o, s_d.grid);
    colormap(ax_o, 'jet');
    title(ax_o, 'Infection Spread');
end

st_e = struct();
grid_init = zeros(30, 30);
grid_init(15, 15) = 1;
st_e.grid = grid_init;

simulate('algorithm', 'step', @spread_step, 'draw', @spread_draw, 'state', st_e, 'prob', 0.2, 'recovery_rate', 0.05);

disp('Epidemiology Lab Session Complete.');
