% 62_bioinformatics_genetics.m
% UniLab Bioinformatics: Genetic Algorithm for Optimization
% This script implements a genetic algorithm to find the global maximum of a complex function.

clear all;
close all;
clc;

disp('🧬 UniLab Bioinformatics & Genetics Lab');
disp('=======================================');

%% 1. Problem Definition: The "Hidden Landscape"
% We want to maximize a function with many local peaks
f_target = @(x) exp(-0.1*x.^2) .* cos(2*x) + 0.5 * sin(5*x);

x_range = linspace(-10, 10, 500);
y_true = f_target(x_range)

figure;
plot(x_range, y_true, 'w--', 'LineWidth', 1); hold on;
title('Genetic Algorithm: Global Max Search');
xlabel('Genotype (x)'); ylabel('Fitness f(x)');

%% 2. Genetic Algorithm Implementation
disp('--- 1. Initializing Population ---');
pop_size = 20;
n_generations = 50;
mutation_rate = 0.1;

% Initial population (random positions)
pop = rand(pop_size, 1) * 20 - 10;
fitness = f_target(pop);

h_pop = scatter(pop, fitness, 50, 'r', 'filled');
legend('Target Landscape', 'Current Population');

disp('Running Evolution...');
for gen = 1:n_generations
    % 1. Selection (Tournament selection)
    new_pop = zeros(size(pop));
    for i = 1:pop_size
        idx1 = randi(pop_size);
        idx2 = randi(pop_size);
        if fitness(idx1) > fitness(idx2)
            new_pop(i) = pop(idx1);
        else
            new_pop(i) = pop(idx2);
        end
    end
    
    % 2. Crossover (Simple averaging)
    for i = 1:2:pop_size
        if rand() < 0.8
            p1 = new_pop(i); p2 = new_pop(i+1);
            alpha = rand();
            new_pop(i) = alpha*p1 + (1-alpha)*p2;
            new_pop(i+1) = alpha*p2 + (1-alpha)*p1;
        end
    end
    
    % 3. Mutation
    mutation = (rand(pop_size, 1) - 0.5) .* (rand(pop_size, 1) < mutation_rate);
    pop = new_pop + mutation;
    
    % Update fitness
    fitness = f_target(pop);
    
    % Optimization Trace
    [best_f, best_idx] = max(fitness);
    if mod(gen, 10) == 0
        fprintf('Generation %d: Best Fitness = %.4f at x = %.4f\n', gen, best_f, pop(best_idx));
    end
end

%% 3. Final Results
[final_best_f, final_best_idx] = max(fitness);
scatter(pop, fitness, 30, 'b', 'filled');
plot(pop(final_best_idx), final_best_f, 'gs', 'MarkerSize', 15, 'LineWidth', 2);
legend('Target Landscape', 'Initial State', 'Final Population', 'Global Winner');

fprintf('\nEvolution Complete.\n');
fprintf('Global Maximum Found: f(%.4f) = %.4f\n', pop(final_best_idx), final_best_f);

disp('Bioinformatics Genetics Session Complete.');
