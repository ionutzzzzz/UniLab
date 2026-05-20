% 05_custom_algorithms.m
% UniLab Algorithm Visualizer: Building Custom Visual Simulations

disp('🛠️ UniLab Custom Algorithm Visualizer');
disp('======================================');

% 1. Define Initial State
state = struct();
state.x = 0;
state.y = 0;
state.history = [0, 0];
state.steps = 0;
state.max_dist = 0;

% 2. Define the Step Function (Algorithm Logic)
function s = walk_step(s, params)
    % Take a random step
    dx = randn() * params.step_size;
    dy = randn() * params.step_size;
    
    s.x = s.x + dx;
    s.y = s.y + dy;
    s.history = [s.history; s.x s.y];
    s.steps = s.steps + 1;
    
    % Track max distance from origin
    dist = sqrt(s.x^2 + s.y^2);
    if dist > s.max_dist
        s.max_dist = dist;
    end
    
    % Update dashboard label
    uiset('dist_lbl', ['Max Distance: ', num2str(s.max_dist)]);
end

% 3. Define the Draw Function (Visualization)
function walk_draw(ax, s)
    % Plot history with fading alpha-like effect (simulated by line style)
    plot(ax, s.history(:,1), s.history(:,2), 'b-', 'LineWidth', 1.0);
    
    % Current position
    plot(ax, s.x, s.y, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    
    % Target circle
    theta = 0:0.1:2*pi;
    plot(ax, 5*cos(theta), 5*sin(theta), 'k--');
    
    title(ax, ['Random Walk: Step ', num2str(s.steps)]);
    uitext(s.x + 0.1, s.y + 0.1, 'Current');
end

% 4. Custom UI Initialization
function my_init()
    uilabel('header', '--- Random Walk Params ---');
    uilabel('dist_lbl', 'Max Distance: 0');
    uibutton('Reset History', @() disp('Reset command logged.'));
end

% 5. Launch Simulation
disp('Launching Custom Random Walk Visualizer...');
simulate('algorithm', 'step', @walk_step, 'draw', @walk_draw, 'state', state, 'step_size', 0.5, 'on_init', @my_init);

disp(' ');
disp('Algorithm Visualizer Session Complete.');
