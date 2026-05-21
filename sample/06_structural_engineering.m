% 06_structural_engineering.m
% UniLab Structural Engineering: Finite Element Truss Analysis

disp('🏗️ UniLab Structural Engineering Studio');
disp('=======================================');

%% 1. Truss Stiffness Analysis (2D)
disp('--- 1. 2D Truss Finite Element Analysis ---');
% Simple bridge truss section
nodes = [0, 0; 2, 0; 1, 1.5]; % x, y coordinates
elements = [1, 2; 2, 3; 3, 1]; % connectivity
E = 200e9; A = 0.01; % Material properties

K_global = zeros(6, 6);
for e = 1:size(elements, 1)
    n1 = elements(e, 1); n2 = elements(e, 2);
    p1 = nodes(n1, :); p2 = nodes(n2, :);
    L = sqrt(sum((p2-p1).^2));
    c = (p2(1)-p1(1))/L; s = (p2(2)-p1(2))/L;
    
    k_local = (E*A/L) * [ c*c, c*s, -c*c, -c*s;
                         c*s, s*s, -c*s, -s*s;
                        -c*c, -c*s,  c*c,  c*s;
                        -c*s, -s*s,  c*s,  s*s];
    
    % Explicit indices to avoid transpiler vector concat issues
    i1 = 2*n1-1; i2 = 2*n1; i3 = 2*n2-1; i4 = 2*n2;
    dofs = [i1, i2, i3, i4];
    
    % Assign block
    K_global(dofs, dofs) = K_global(dofs, dofs) + k_local;
end

disp('Global Stiffness Matrix Computed.');
disp(K_global);

%% 2. Structural Optimization
disp(' ');
disp('--- 2. Beam Deflection (Interactive) ---');

function s_out = beam_step(s_in, p)
    s_out = s_in;
    s_out.P = s_in.P + randn() * 10;
end

function beam_draw(ax, s)
    x_pos = linspace(0, s.L, 100);
    E_mod = 200e9; I_mom = 1e-4;
    y_defl = - (s.P * x_pos.^2 ./ (6 * E_mod * I_mom)) .* (3 * s.L - x_pos);
    plot(ax, x_pos, y_defl, 'b-', 'LineWidth', 3);
    title(ax, ['Cantilever Beam Deflection (Load: ', num2str(s.P), ' N)']);
    xlabel(ax, 'Position (m)'); ylabel(ax, 'Deflection (m)');
    ylim(ax, [-0.5, 0.1]); grid(ax, 'on');
end

% Simulating a cantilever beam deflection
simulate('algorithm', 'step', @beam_step, 'draw', @beam_draw, 'state', struct('P', 1000, 'L', 10), 'E', 200e9, 'I', 1e-4);

disp('Structural Engineering Studio Complete.');
