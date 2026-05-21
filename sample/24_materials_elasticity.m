% 24_materials_elasticity.m
% Demonstrates solid mechanics and material property relationships

disp('💎 UniLab Materials Elasticity');
disp('==============================');

disp('--- Material Property Relationships ---');
% Let's analyze a sample of Titanium alloy
E_titanium = 116e9; % Young's Modulus in Pascals
nu_titanium = 0.34;  % Poisson's Ratio

% Calculate derived moduli
G = shear_modulus(E_titanium, nu_titanium);
K = bulk_modulus(E_titanium, nu_titanium);

fprintf('Titanium Alloy Properties:
');
fprintf('  Young''s Modulus (E): %.2f GPa
', E_titanium / 1e9);
fprintf('  Poisson''s Ratio (v): %.2f
', nu_titanium);
fprintf('  Shear Modulus (G):   %.2f GPa
', G / 1e9);
fprintf('  Bulk Modulus (K):    %.2f GPa
', K / 1e9);

disp('--- Stress & Strain Testing ---');
Force_applied = 50000; % Newtons
Area_cross_section = 0.0005; % m^2

sigma = stress_calc(Force_applied, Area_cross_section);
epsilon = sigma / E_titanium; % Using Hooke's Law in 1D

fprintf('Applied Tensile Stress: %.2f MPa
', sigma / 1e6);
fprintf('Resulting Axial Strain: %.6f
', epsilon);
