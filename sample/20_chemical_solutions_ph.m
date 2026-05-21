% 20_chemical_solutions_ph.m
% Demonstrates chemical concentrations and pH calculations

disp('⚗️ UniLab Chemistry Solutions');
disp('=============================');

disp('--- 1. Solution Concentration ---');
moles_NaCl = 0.25; 
liters_water = 0.500;
kg_water = 0.500; % Approx 1kg/L for water

M = molarity(moles_NaCl, liters_water);
m = molality(moles_NaCl, kg_water);
fprintf('NaCl Solution Molarity: %.3f M
', M);
fprintf('NaCl Solution Molality: %.3f m
', m);

disp('--- 2. pH Titration Curve Simulation ---');
% Simulate adding strong base (OH-) to strong acid (H+)
H_initial = 0.1; % 0.1M HCl
volumes_base = linspace(0, 0.2, 100);
pH_vals = zeros(1, 100);

for i = 1:100
    % Extremely simplified neutralization for visualization
    H_remaining = H_initial - (volumes_base(i) * 0.1); 
    if H_remaining > 1e-7
        pH_vals(i) = ph_calc(H_remaining);
    else
        % Past equivalence point
        OH_excess = abs(H_remaining) + 1e-7;
        pOH = -log10_custom(OH_excess);
        pH_vals(i) = 14 - pOH;
    end
end

figure; plot(volumes_base, pH_vals, 'm-', 'LineWidth', 2);
title('Strong Acid - Strong Base Titration Curve'); 
xlabel('Volume of Base Added (L)'); ylabel('pH'); grid on;
