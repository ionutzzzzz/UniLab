% 40_number_theory_exploration.m
% UniLab Number Theory: Primes, Conjectures & Sequences

clear all;
clc;

disp('🔢 UniLab Number Theory Explorer');
disp('=================================');

%% 1. Goldbach's Conjecture
disp('--- 1. Goldbach Pair Decomposition ---');
n_gold = 100;
pairs = goldbach_conjecture_check(n_gold);

fprintf('Goldbach pairs for n=%d:\n', n_gold);
for i = 1:size(pairs, 1)
    fprintf('  %d = %d + %d\n', n_gold, pairs(i,1), pairs(i,2));
end

%% 2. Collatz Sequence (3n+1)
disp(' ');
disp('--- 2. Collatz Sequence Visualization ---');
start_n = 27;
seq = collatz_sequence(start_n);

fprintf('Collatz sequence for %d reached 1 in %d steps.\n', start_n, length(seq)-1);

figure;
plot(seq, 'b-o', 'MarkerSize', 4);
title(['Collatz Sequence (3n+1) for n=', num2str(start_n)]);
xlabel('Step'); ylabel('Value');
grid on;

%% 3. Prime Counting Distribution
disp(' ');
disp('--- 3. Prime Counting Function \pi(n) ---');
n_range = 10:10:500;
pi_vals = zeros(size(n_range));
li_approx = zeros(size(n_range)); % n/ln(n) approximation

for i = 1:length(n_range)
    pi_vals(i) = prime_counting_function(n_range(i));
    li_approx(i) = n_range(i) / log(n_range(i));
end

figure;
plot(n_range, pi_vals, 'r-', 'LineWidth', 2); hold on;
plot(n_range, li_approx, 'b--', 'LineWidth', 1.5);
title('Prime Counting Function \pi(n) vs n/ln(n)');
xlabel('n'); ylabel('Count of Primes \le n');
legend('\pi(n) Actual', 'Prime Number Theorem Approx');
grid on; hold off;

%% 4. Special Numbers
disp(' ');
disp('--- 4. Perfect and Harmonic Numbers ---');
fprintf('Perfect numbers up to 1000:\n');
for i = 1:1000
    if is_perfect_number(i)
        fprintf('  %d\n', i);
    end
end

h_10 = harmonic_number(10);
fprintf('10th Harmonic Number (H10): %.6f\n', h_10);

disp('Number Theory Exploration Complete.');