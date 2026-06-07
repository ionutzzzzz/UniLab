% 55_chemical_process_yield.m
% UniLab Chemical Engineering: Stoichiometry and Equilibrium

clear all;
clc;

disp('🧪 UniLab Chemical Process Engineering');
disp('======================================');

%% 1. Stoichiometry & Limiting Reactants
disp('--- 1. Reaction Yield: Ammonia Synthesis ---');
% N2 + 3H2 -> 2NH3
coeffs = [1, 3]; % Coefficients for reactants
moles_available = [10.0, 25.0]; % Available N2 and H2

[lim_idx, max_product_moles] = limiting_reactant(moles_available, coeffs);

% Ratio to NH3 is 2 for 1 mole of N2 or 2/3 for H2
if lim_idx == 1
    product_ratio = 2.0;
    reactant_name = 'Nitrogen (N2)';
else
    product_ratio = 2.0 / 3.0;
    reactant_name = 'Hydrogen (H2)';
end

fprintf('Limiting Reactant: %s\n', reactant_name);

% Calculate theoretical yield in grams
molar_mass_NH3 = 17.03;
theo_yield_g = theoretical_yield(moles_available(lim_idx), molar_mass_NH3, product_ratio);

% Assume actual yield from experiment
actual_yield_g = 250.0;
p_yield = percent_yield(actual_yield_g, theo_yield_g);

fprintf('Theoretical Yield: %.2f g\n', theo_yield_g);
fprintf('Actual Yield:      %.2f g\n', actual_yield_g);
fprintf('Percentage Yield:  %.2f%%\n', p_yield);

%% 2. Equilibrium & Temperature (Arrhenius)
disp(' ');
disp('--- 2. Reaction Kinetics & Equilibrium ---');
% Rate constant at T=300K
A = 1e11; Ea = 75000; % J/mol
T1 = 300;
k1 = arrhenius_equation(A, Ea, T1);

% Rate constant at T=350K
T2 = 350;
k2 = arrhenius_equation(A, Ea, T2);

fprintf('Rate constant at %dK: %.2e\n', T1, k1);
fprintf('Rate constant at %dK: %.2e\n', T2, k2);
fprintf('Reaction is %.1f times faster at %dK.\n', k2/k1, T2);

% Equilibrium conversion
Kc = 0.5; % Equilibrium constant at T2
delta_n = 2 - (1 + 3); % Change in moles for N2 + 3H2 -> 2NH3
Kp = equilibrium_constant_kp_kc(Kc, delta_n, T2);

fprintf('Equilibrium Kc: %.4f\n', Kc);
fprintf('Equilibrium Kp: %.4f (at %dK)\n', Kp, T2);

%% 3. Titration & pH (Process Quality Control)
disp(' ');
disp('--- 3. Product Acidity Control ---');
h_conc = 1.2e-4; % H+ concentration in final product
ph = ph_calc(h_conc);
fprintf('Final Product pH: %.2f\n', ph);

if ph < 4.0
    disp('Warning: Product is too acidic. Buffer required.');
else
    disp('Status: Product pH within acceptable range.');
end

disp('Chemical Process Engineering Analysis Complete.');
