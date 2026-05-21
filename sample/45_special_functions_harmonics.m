% 45_special_functions_harmonics.m
% UniLab Special Functions: Bessels, Gamma & Error Functions

clear all;
clc;

disp('💠 UniLab Special Functions Study');
disp('==================================');

%% 1. Spherical Bessel Functions (Waves)
disp('--- 1. Spherical Bessel of First Kind ---');
x = linspace(0.1, 20, 100);
j0 = spherical_bessel_j(0, x);
j1 = spherical_bessel_j(1, x);

figure;
plot(x, j0, 'b-', 'LineWidth', 2); hold on;
plot(x, j1, 'r--', 'LineWidth', 2);
title('Spherical Bessel Functions j_n(x)');
legend('j_0(x)', 'j_1(x)');
grid on; hold off;

%% 2. Incomplete Gamma (Statistics)
disp(' ');
disp('--- 2. Incomplete Gamma Functions ---');
a = 2.5;
x_val = 1.0;
low = incomplete_gamma_lower(a, x_val);
high = incomplete_gamma_upper(a, x_val);
total = gamma_stirling(a);

fprintf('Incomplete Gamma (a=2.5, x=1.0):\n');
fprintf('  Lower P(a,x): %.4f\n', low);
fprintf('  Upper Q(a,x): %.4f\n', high);
fprintf('  Sum (should be Gamma(a)): %.4f (Actual Gamma(a): %.4f)\n', low+high, total);

%% 3. Beta & Incomplete Beta
disp(' ');
disp('--- 3. Beta Function Relationship ---');
x_beta = 0.5;
a_b = 2.0; b_b = 3.0;
inc_b = incomplete_beta_function(x_beta, a_b, b_b);
fprintf('Incomplete Beta B(%.1f; %.1f, %.1f) approx: %.4f\n', x_beta, a_b, b_b, inc_b);

%% 4. Error Function Complement
disp(' ');
disp('--- 4. Inverse Error Function ---');
probs = [0.1, 0.5, 0.9];
for p = probs
    x_inv = inverse_error_function_approx(p);
    erf_x = erf_approx(x_inv);
    fprintf('InvErf(%.1f) = %.4f (Check Erf(%.4f) = %.4f)\n', p, x_inv, x_inv, erf_x);
end

disp('Special Functions session Complete.');