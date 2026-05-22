% 30_robotics_arm_kinematics.m
% UniLab Robotics: 2-DOF Planar Arm Kinematics & Path Planning

clear all;
close all;
clc;

disp('🤖 UniLab Robotics Laboratory');
disp('==============================');

%% 1. Forward Kinematics (FK)
disp('--- 1. Forward Kinematics ---');
L1 = 1.0; L2 = 0.8; % Link lengths

function pos = arm_fk(theta1, theta2, L1, L2)
    % theta1, theta2 in radians
    x = L1 * cos(theta1) + L2 * cos(theta1 + theta2);
    y = L1 * sin(theta1) + L2 * sin(theta1 + theta2);
    pos = [x, y];
end

% Test FK
t1 = pi/4; t2 = pi/6;
p = arm_fk(t1, t2, L1, L2);
fprintf('Arm Tip Position for [%.2f, %.2f]: (%.2f, %.2f)\n', t1, t2, p(1), p(2));

%% 2. Inverse Kinematics (IK)
disp('--- 2. Inverse Kinematics ---');

function q = arm_ik(x, y, L1, L2)
    % Cosine law for theta2
    D = (x^2 + y^2 - L1^2 - L2^2) / (2 * L1 * L2);
    % Elbow down solution
    t2 = atan2(sqrt(1 - D^2), D);
    t1 = atan2(y, x) - atan2(L2 * sin(t2), L1 + L2 * cos(t2));
    q = [t1, t2];
end

% Test IK (should return original angles)
q_res = arm_ik(p(1), p(2), L1, L2);
disp('IK Result (Should match test FK angles):');
disp(q_res);

%% 3. Trajectory Generation (Circle Path)
disp('--- 3. Path Following Simulation ---');
N_pts = 100;
t_path = linspace(0, 2*pi, N_pts);
center = [0.8, 0.8]; radius = 0.4;

x_path = center(1) + radius * cos(t_path);
y_path = center(2) + radius * sin(t_path);

theta_hist = zeros(N_pts, 2);
for i = 1:N_pts
    theta_hist(i, :) = arm_ik(x_path(i), y_path(i), L1, L2);
end

figure;
plot(x_path, y_path, 'k--', 'LineWidth', 1); hold on;
% Draw arm at one point
q_ex = theta_hist(50, :);
j1 = [L1 * (cos(q_ex(1))), L1 * (sin(q_ex(1)))];
plot([0, j1(1), x_path(50)], [0, j1(2), y_path(50)], 'bo-', 'LineWidth', 3);
title('Robotic Arm Circular Trajectory Planning');
xlabel('X (m)'); ylabel('Y (m)');
axis equal; grid on;

%% 4. Interactive Simulation
disp(' ');
disp('--- 4. Interactive Robot Arm Animation ---');

function s_n = robot_step(s_c, p_p)
    s_n = s_c;
    s_n.t = s_c.t + 0.05;
    % Oscillate target
    xt = 0.8 + 0.3 * sin(s_n.t);
    yt = 0.8 + 0.3 * cos(s_n.t * 0.5);
    q = arm_ik(xt, yt, 1.0, 0.8);
    s_n.q = q;
    s_n.target = [xt, yt];
    s_n.h = [s_c.h; [xt, yt]];
    if size(s_n.h, 1) > 200, s_n.h = s_n.h(end-199:end, :); end
end

function robot_draw(ax, s)
    L1 = 1.0; L2 = 0.8;
    j1 = [L1 * (cos(s.q(1))), L1 * (sin(s.q(1)))];
    tip = [((j1(1)) + L2 * (cos(s.q(1) + s.q(2)))), ((j1(2)) + L2 * (sin(s.q(1) + s.q(2))))];
    
    plot(ax, s.h(:, 1), s.h(:, 2), 'g:', 'LineWidth', 1); hold(ax, 'on');
    plot(ax, [0, j1(1), tip(1)], [0, j1(2), tip(2)], 'b-o', 'LineWidth', 4, 'MarkerSize', 10);
    plot(ax, s.target(1), s.target(2), 'rx', 'MarkerSize', 15, 'LineWidth', 2);
    title(ax, 'Real-time Inverse Kinematics Tracking');
    xlim(ax, [-0.5, 2.0]); ylim(ax, [-0.5, 2.0]); grid(ax, 'on'); hold(ax, 'off');
end

st_r = struct('t', 0, 'q', [0, 0], 'target', [1.2, 0.5], 'h', []);
simulate('algorithm', 'step', @robot_step, 'draw', @robot_draw, 'state', st_r);

disp('Robotics Kinematics Session Complete.');