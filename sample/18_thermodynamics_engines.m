% 18_thermodynamics_engines.m
% Demonstrates Ideal Gas expansions and Carnot Engine efficiency

disp('🔥 UniLab Thermodynamics');
disp('========================');

disp('--- 1. Carnot Heat Engine ---');
T_hot = 900; % K (Combustion temperature)
T_cold = 300; % K (Exhaust temperature)

eff = carnot_efficiency(T_cold, T_hot);
fprintf('Maximum Theoretical (Carnot) Efficiency of the engine: %.2f%%
', eff * 100);

disp('--- 2. Ideal Gas Isothermal vs Adiabatic Expansion ---');
P1 = 1013250; % 10 atm
V1 = 0.005; % m^3
T1 = 500; % K
R = 8.314;
n = ideal_gas_law_n(P1, V1, R, T1);

V2 = 0.02; % Expanded volume
W_isothermal = isothermal_work(n, R, T1, V1, V2);

gamma_diatomic = 1.4; % For air/N2
P2_adiabatic = P1 * (V1 / V2)^gamma_diatomic;
W_adiabatic = adiabatic_work_ideal_gas(P1, V1, P2_adiabatic, V2, gamma_diatomic);

fprintf('Work extracted during ISOTHERMAL expansion: %.2f Joules
', W_isothermal);
fprintf('Work extracted during ADIABATIC expansion: %.2f Joules
', W_adiabatic);
