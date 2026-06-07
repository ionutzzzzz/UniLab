% 35_thermodynamic_cycles_analysis.m
% UniLab Thermodynamics: Heat Engine Cycle Comparisons

clear all;
close all;
clc;

disp('🔥 UniLab Thermodynamic Cycle Analysis');
disp('=======================================');

%% 1. Otto vs Diesel Cycle Efficiency
disp('--- 1. IC Engine Efficiency Comparison ---');
r_range = 5:2:25; % Compression ratios
gamma = 1.4;    % Air ratio of specific heats
rc_diesel = 2.0; % Cutoff ratio for Diesel

eff_otto = zeros(size(r_range));
eff_diesel = zeros(size(r_range));

for i = 1:length(r_range)
    eff_otto(i) = otto_cycle_efficiency(r_range(i), gamma);
    eff_diesel(i) = diesel_cycle_efficiency(r_range(i), rc_diesel, gamma);
end

figure;
plot(r_range, eff_otto * 100, 'r-o', 'LineWidth', 2); hold on;
plot(r_range, eff_diesel * 100, 'b-s', 'LineWidth', 2);
title('Efficiency: Otto vs. Diesel Cycle');
xlabel('Compression Ratio (r)'); ylabel('Thermal Efficiency (%)');
legend('Otto Cycle', 'Diesel Cycle (rc=2)');
grid on; hold off;

%% 2. Rankine Cycle (Power Plant)
disp(' ');
disp('--- 2. Steam Power Plant (Rankine) ---');
% High-pressure steam entering turbine
h1 = 3400; % kJ/kg
% Exit turbine
h2 = 2400; % kJ/kg
% Exit condenser
h3 = 190;  % kJ/kg
% Exit pump
h4 = 200;  % kJ/kg

eff_rankine = rankine_cycle_efficiency_simple(h1, h2, h3, h4);
fprintf('Simple Rankine Cycle Efficiency: %.2f%%\n', eff_rankine * 100);

%% 3. Psychrometrics: Dew Point & Humidity
disp(' ');
disp('--- 3. Humidity Analysis ---');
Temp_C = 25.0;
Relative_Hum = 60.0;

T_dew = psychrometric_dew_point(Temp_C, Relative_Hum);
fprintf('At %.1f C and %.0f%% humidity, the Dew Point is: %.2f C\n', Temp_C, Relative_Hum, T_dew);

%% 4. Chemical Thermodynamics
disp(' ');
disp('--- 4. Reaction Equilibrium (Van ''t Hoff) ---');
delta_H = -57200; % J/mol (Exothermic reaction)
T1 = 298.15;      % 25 C
T2 = 373.15;      % 100 C

ln_ratio = van_t_hoff_equation(delta_H, T1, T2);
K_ratio = exp(ln_ratio);

fprintf('Ratio of Equilibrium Constants K(373K)/K(298K): %.4f\n', K_ratio);
if K_ratio < 1
    disp('Result: Equilibrium shifted towards reactants at higher temperature.');
end

disp('Thermodynamics Session Complete.');