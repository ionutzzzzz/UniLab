% 14_pure_mathematics.m
% Demonstrates advanced mathematical functions including hyperbolic geometry and combinatorics

clear all;
close all;
clc;

disp('📐 UniLab Pure Mathematics Lab');
disp('================================');

disp('--- 1. Catenary Curve (Hanging Chain) ---');
% A hanging chain follows a hyperbolic cosine curve: y = a * cosh(x/a)
x = linspace(-20, 20, 100);
a_tension = 10.0;
y = a_tension * cosh_custom(x / a_tension);

figure;
plot(x, y, 'b-', 'LineWidth', 2);
title('Catenary Curve: Hanging Suspension Bridge Cable'); 
xlabel('Distance (m)'); ylabel('Height (m)');
grid on;

disp('--- 2. Advanced Combinatorics (Poker Probabilities) ---');
% Calculate the number of possible 5-card poker hands
n_cards = 52; k_hand = 5;
hands = nchoosek_custom(n_cards, k_hand);

% Calculate Royal Flush probability (4 possible suits out of total hands)
prob_royal = 4 / hands;

fprintf('Total possible 5-card poker hands: %d
', hands);
fprintf('Probability of getting a Royal Flush: %.8f%%
', prob_royal * 100);
