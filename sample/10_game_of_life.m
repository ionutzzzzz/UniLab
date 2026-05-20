% 10_game_of_life.m
% UniLab Cellular Automata: Conways Game of Life

disp('🧬 UniLab Cellular Automata Lab');
disp('================================');

% 1. Define Initial State (Grid)
grid_size = 40;
state = struct();
state.grid = (rand(grid_size, grid_size) > 0.8) * 1.0;
state.gen = 0;

% 2. Define the Evolution Step (Logic)
function s = evolve_life(s, params)
    G = s.grid;
    [R, C] = size(G);
    % Fast neighbor counting using 2D slicing
    N = zeros(R, C);
    N(2:end-1, 2:C-1) = G(1:end-2, 1:C-2) + G(1:end-2, 2:C-1) + G(1:end-2, 3:end) + ...
                        G(2:end-1, 1:C-2)                    + G(2:end-1, 3:end) + ...
                        G(3:end,   1:C-2) + G(3:end,   2:C-1) + G(3:end,   3:end);
    
    % Rules: 3 neighbors birth, 2-3 neighbors survive
    new_G = (G == 1 & (N == 2 | N == 3)) | (G == 0 & N == 3);
    
    s.grid = new_G;
    s.gen = s.gen + 1;
    uiset('gen_lbl', ['Generation: ', num2str(s.gen)]);
end

% 3. Define the Visualization
function draw_life(ax, s)
    % Using heatmap style for grid
    imagesc(ax, s.grid);
    title(ax, ['Game of Life - Generation: ', num2str(s.gen)]);
    colormap(ax, 'bone');
end

% 4. UI Dashboard
function life_init()
    uilabel('header', '--- Life Controls ---');
    uilabel('gen_lbl', 'Generation: 0');
    uibutton('Reset Grid', @() disp('Grid reset requested.'));
end

% 5. Launch Simulation
disp('Launching Conway''s Game of Life (Algorithm Simulator)...');
simulate('algorithm', 'step', @evolve_life, 'draw', @draw_life, 'state', state, 'on_init', @life_init);

disp(' ');
disp('Cellular Automata Session Complete.');
