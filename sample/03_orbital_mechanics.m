% 03_orbital_mechanics.m
% UniLab Aerospace Engineering: Orbital Mechanics & N-Body Systems

disp('🚀 UniLab Aerospace & Orbital Mechanics');
disp('=======================================');

%% 1. Keplerian Orbit (Satellite Dynamics)
disp('--- 1. Satellite Orbit (Elliptical) ---');
a_axis = 1.0; e_ecc = 0.5; 
theta_vec = linspace(0, 2*pi, 500);
r_orbit = a_axis * (1.0 - e_ecc^2) ./ (1.0 + e_ecc * cos(theta_vec));
x_orbit = r_orbit .* cos(theta_vec);
y_orbit = r_orbit .* sin(theta_vec);

figure;
plot(x_orbit, y_orbit, 'b-', 'LineWidth', 1.5); hold on;
plot(0, 0, 'yo', 'MarkerSize', 15, 'MarkerFaceColor', 'y'); % Central Body
title('Keplerian Orbit: e = 0.5');
axis equal; grid on;
hold off;

%% 2. Restricted 3-Body Problem (Lagrangian Points)
disp(' ');
disp('--- 2. Restricted 3-Body Problem ---');

function s_nxt = cr3bp_step(s_cur, p_par)
    s_nxt = s_cur;
    dt_step = 0.01;
    mu_val = p_par.mu; mu1 = 1.0 - mu_val;
    x_p = s_cur.pos(1); y_p = s_cur.pos(2);
    vx_v = s_cur.vel(1); vy_v = s_cur.vel(2);
    
    r1_d = sqrt((x_p + mu_val)^2 + y_p^2);
    r2_d = sqrt((x_p - mu1)^2 + y_p^2);
    
    ax_a = x_p + 2.0*vy_v - mu1*(x_p + mu_val)/r1_d^3 - mu_val*(x_p - mu1)/r2_d^3;
    ay_a = y_p - 2.0*vx_v - mu1*y_p/r1_d^3 - mu_val*y_p/r2_d^3;
    
    s_nxt.vel = s_cur.vel + [ax_a, ay_a] * dt_step;
    s_nxt.pos = s_cur.pos + s_nxt.vel * dt_step;
    s_nxt.h = [s_cur.h; s_nxt.pos];
    if size(s_nxt.h, 1) > 1000, s_nxt.h = s_nxt.h(end-999:end, :); end
end

function cr3bp_draw(ax_o, s_d)
    plot(ax_o, s_d.h(:, 1), s_d.h(:, 2), 'b-'); hold(ax_o, 'on');
    plot(ax_o, -0.012, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); 
    plot(ax_o, 0.988, 0, 'go', 'MarkerSize', 5, 'MarkerFaceColor', 'g');  
    title(ax_o, 'Restricted 3-Body Problem');
    axis(ax_o, 'equal'); grid(ax_o, 'on'); hold(ax_o, 'off');
end

mu_r = 0.012277471;
st = struct('pos', [0.5, 0.5], 'vel', [-0.5, 0.5], 'h', []);
simulate('algorithm', 'step', @cr3bp_step, 'draw', @cr3bp_draw, 'state', st, 'mu', mu_r);

%% 3. Advanced N-Body Gravity
disp(' ');
disp('--- 3. Multi-Body Gravitational Cluster ---');
simulate('nbody', 'G', 2.0, 'time', [0, 20]);

disp('Orbital Mechanics Session Complete.');
