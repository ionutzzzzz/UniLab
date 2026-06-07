% 57_astronomy_exoplanet_transit.m
% UniLab Astronomy: Exoplanet Detection via Transit Photometry

clear all;
close all;
clc;

disp('🔭 UniLab Exoplanet Discovery Lab');
disp('=================================');

%% 1. Simulating a Light Curve
disp('--- 1. Generating Star Flux with Planet Transit ---');
fs = 1; % 1 sample per hour
t_days = 0:1/24:30; % 30 days of observation
t_hours = t_days * 24;

% Baseline flux (normalized)
flux = ones(size(t_hours)) + randn(size(t_hours)) * 0.0005;

% Planet Parameters
period_hours = 120; % 5-day orbit
transit_duration_hours = 4;
transit_depth = 0.015; % 1% dimming

for i = 1:length(t_hours)
    phase = mod(t_hours(i), period_hours);
    if phase < transit_duration_hours
        flux(i) = flux(i) - transit_depth;
    end
end

figure;
plot(t_days, flux, 'b.', 'MarkerSize', 2);
title('Simulated Stellar Light Curve (Transit Method)');
xlabel('Time (days)'); ylabel('Relative Flux');
grid on;

%% 2. Transit Detection
disp('--- 2. Automated Transit Search ---');
% Invert flux to find "peaks" (which are actually dips)
inv_flux = 1.0 - flux;
[pks, locs] = find_peaks(inv_flux, 0.01);

fprintf('Detected %d potential transits.\n', length(locs));
for i = 1:length(locs)
    fprintf('  Transit %d at t = %.2f days\n', i, t_days(locs(i)));
end

if length(locs) >= 2
    avg_period_hours = mean(diff(t_hours(locs)));
    fprintf('Measured Orbital Period: %.2f hours (%.2f days)\n', avg_period_hours, avg_period_hours/24);
end

%% 3. Orbital Characterization
disp(' ');
disp('--- 3. Exoplanet Orbital Radius ---');
G = 6.674e-11;
M_star = 1.989e30; % 1 Solar Mass
T_sec = avg_period_hours * 3600;

% T = sqrt((4 * pi^2 * a^3) / (G * M))
% a^3 = (T^2 * G * M) / (4 * pi^2)
a = ((T_sec^2 * G * M_star) / (4 * pi()^2))^(1/3);

AU = 1.496e11;
fprintf('Calculated Semi-major Axis: %.2e meters (%.3f AU)\n', a, a/AU);

if a/AU < 0.1
    disp('Classification: Hot Jupiter (Close-in orbit)');
else
    disp('Classification: Terrestrial-like orbit distance');
end

%% 4. Magnitude Calculation
disp(' ');
disp('--- 4. Stellar Magnitude and Distance ---');
d_parsecs = 100;
M_absolute = 4.83; % Sun-like star
m_apparent = apparent_magnitude_calc(M_absolute, d_parsecs);

fprintf('At %d parsecs, a Sun-like star has an Apparent Magnitude of: %.2f\n', d_parsecs, m_apparent);

disp('Exoplanet Characterization Complete.');
