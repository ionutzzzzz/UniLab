% 39_quantum_well_simulation.m
% UniLab Quantum Physics: Well States & Tunneling

clear all;
close all;
clc;

disp('⚛️ UniLab Quantum Well & Tunneling Lab');
disp('=======================================');

%% 1. Infinite Square Well
disp('--- 1. Infinite Well Energy Levels ---');
L_well = 1.0; % Width in nanometers (for scaling)
m_e = 1.0;    % Effective mass (normalized)
hbar = 1.0;   % Planck constant (normalized)

n_levels = 1:5;
E_levels = zeros(size(n_levels));

for n = n_levels
    E_levels(n) = infinite_square_well_energy(n, L_well, m_e, hbar);
    fprintf('Energy Level n=%d : %.4f units\n', n, E_levels(n));
end

figure;
for n = 1:3
    x = linspace(0, L_well, 100);
    psi = sqrt(2/L_well) * sin(n*pi()*x/L_well);
    plot(x, psi + E_levels(n), 'LineWidth', 2); hold on;
end
title('Infinite Square Well: Eigenstates and Energy Levels');
xlabel('Position (x)'); ylabel('Energy');
grid on; hold off;

%% 2. Finite Barrier Transmission (Tunneling)
disp(' ');
disp('--- 2. Quantum Tunneling Probability ---');
V0 = 10.0;     % Barrier height
L_bar = 0.5;   % Barrier width
E_range = linspace(0.1, 20, 100);
T_coeff = zeros(size(E_range));

for i = 1:length(E_range)
    T_coeff(i) = finite_square_well_transmission(E_range(i), V0, L_bar, m_e, hbar);
end

figure;
plot(E_range, T_coeff, 'b-', 'LineWidth', 2); hold on;
plot([V0, V0], [0, 1], 'r--'); % Barrier height line
title('Transmission Coefficient through a Finite Barrier');
xlabel('Particle Energy (E)'); ylabel('Transmission Probability (T)');
legend('Transmission', 'Barrier Height V0');
grid on; hold off;

%% 3. Pauli Spin Matrices
disp(' ');
disp('--- 3. Spin Operator Algebra ---');
[sx, sy, sz] = pauli_matrices();
[Sx, Sy, Sz, Sp, Sm] = spin_operators(0.5);

disp('Commutation Relation [Sx, Sy]:');
comm = Sx*Sy - Sy*Sx;
disp(comm);
disp('Expected result: i * hbar * Sz');
disp(1j * Sz);

disp('Quantum Well Simulation Complete.');