% 68_advanced_biomedical_cardiac.m
% UniLab Complex Biomedical Simulation: Action Potential Dynamics & Firing Rates
% This script studies neural action potential spikes under variable injected currents 
% using the Hodgkin-Huxley equations and evaluates cardiac potential patterns.

clear all;
close all;
clc;

disp('🧬 UniLab Advanced Neural & Cardiac Action Potential Study');
disp('========================================================');

% Study Hodgkin-Huxley neuron response to different injected currents
currents = [5.0, 15.0, 30.0];
dur = 50.0; % duration in ms

disp('Simulating Hodgkin-Huxley equations over varying external stimulus currents...');

for k = 1:length(currents)
    I_ext = currents(k);
    fprintf('\nSimulating with injected current: %.1f uA/cm^2...\n', I_ext);
    
    [t, V, m, h, n] = biomedical.hodgkin_huxley(I_ext, dur);
    
    % Count action potential spikes (V > 0 mV threshold)
    spikes = 0;
    in_spike = false;
    for i = 1:length(V)
        if V(i) > 0.0
            if ~in_spike
                spikes = spikes + 1;
                in_spike = true;
            end
        else
            in_spike = false;
        end
    end
    
    fprintf('  Total spikes counted: %d\n', spikes);
    fprintf('  Peak action potential voltage: %.2f mV\n', max(V));
    fprintf('  Steady state gating variable (n - potassium activation): %.4f\n', n(end));
    
    % Plot each simulation result
    figure;
    plot(t, V, 'y-', 'LineWidth', 1.5);
    title(sprintf('HH Neuron: Injected Current = %.1f uA/cm^2 (Spikes: %d)', I_ext, spikes));
    xlabel('Time (ms)');
    ylabel('Voltage (mV)');
    grid on;
end

disp('--------------------------------------------------------');
disp('Simulating cardiac action potential (FitzHugh-Nagumo model)...');
cardiac_dur = 120.0;
[t_c, v_c, w_c] = biomedical.cardiac_action_potential(cardiac_dur);

% Calculate statistics
disp('Cardiac action potential simulation stats:');
fprintf('  Max excitation potential (v): %.4f\n', max(v_c));
fprintf('  Min excitation potential (v): %.4f\n', min(v_c));

figure;
plot(t_c, v_c, 'c-', t_c, w_c, 'r-', 'LineWidth', 1.5);
title('Cardiac FitzHugh-Nagumo Activation (v) and Recovery (w)');
xlabel('Time (s)');
ylabel('State Variables');
grid on;

disp('Biomedical simulation completed successfully.');
