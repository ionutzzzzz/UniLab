% 23_quantum_wave_particle.m
% Demonstrates the wave-particle duality and energy levels

clear all;
clc;

disp('⚛️ UniLab Advanced Quantum Mechanics');
disp('=====================================');

h = 6.626e-34; % Planck's constant
hbar = h / (2 * pi());

disp('--- 1. De Broglie Wavelength (Macro vs Micro) ---');
m_electron = 9.11e-31; v_electron = 2.18e6; % Electron in hydrogen atom
m_bullet = 0.015; v_bullet = 1000; % High speed bullet

lambda_e = de_broglie_wavelength(h, momentum(m_electron, v_electron));
lambda_b = de_broglie_wavelength(h, momentum(m_bullet, v_bullet));

fprintf('De Broglie Wavelength of an orbiting electron: %.2e meters
', lambda_e);
fprintf('De Broglie Wavelength of a sniper bullet: %.2e meters
', lambda_b);

disp('--- 2. Heisenberg Uncertainty Principle ---');
dx_dp = heisenberg_uncertainty_x_p(hbar);
fprintf('Minimum position-momentum uncertainty limit: %.2e J*s
', dx_dp);

disp('--- 3. Bohr Model of Hydrogen ---');
disp('Energy levels of the Hydrogen atom:');
for n = 1:5
    E_n = energy_level_hydrogen(n);
    fprintf('  Level n=%d : %.3f eV
', n, E_n);
end
