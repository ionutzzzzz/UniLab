% 01_quantum_mechanics.m
% UniLab Quantum Physics: 1D Schrodinger Equation & Wavefunction Evolution

disp('⚛️ UniLab Quantum Mechanics Suite');
disp('===================================');

%% 1. Quantum Harmonic Oscillator (Eigenstates)
disp('--- 1. Harmonic Oscillator Eigenstates ---');
x = linspace(-5, 5, 500);
m = 1; hbar = 1; omega = 1;

% Hermite polynomials (recursive implementation)
function H = hermite_poly(n, x)
    if n == 0
        H = ones(size(x));
    elseif n == 1
        H = 2 * x;
    else
        H = 2 * x .* hermite_poly(n-1, x) - 2 * (n-1) * hermite_poly(n-2, x);
    end
end

% Wavefunction for level n
function psi = quantum_ho_psi(n, x, m, hbar, omega)
    alpha = sqrt(m * omega / hbar);
    norm = 1 / sqrt(2^n * factorial(n)) * (alpha^2 / pi)^(1/4);
    psi = norm * exp(-alpha^2 * x.^2 / 2) .* hermite_poly(n, alpha * x);
end

figure;
hold on;
colors = {'r', 'g', 'b', 'm'};
for n = 0:3
    psi = quantum_ho_psi(n, x, m, hbar, omega);
    plot(x, psi + n + 0.5, 'LineWidth', 2, 'Color', colors{n+1});
end
title('QHO Eigenstates: \psi_n(x)');
xlabel('Position (x)'); ylabel('Energy / Amplitude');
grid on;
hold off;

%% 2. Quantum Tunneling Simulation
disp(' ');
disp('--- 2. Quantum Tunneling (Wave Packet) ---');
state = struct();
state.N = 100;
state.x = linspace(-10, 10, state.N);
state.dx = state.x(2) - state.x(1);
state.dt = 0.05;
V_barrier = zeros(1, state.N);
V_barrier(state.N/2 - 3 : state.N/2 + 3) = 15.0; % Barrier
state.V = V_barrier;
k0 = 2.0;
state.psi = exp(-0.5 * (state.x + 5).^2) .* exp(1j * k0 * state.x);
state.psi = state.psi / sqrt(sum(abs(state.psi).^2) * state.dx);

function s = schrodinger_step(s, params)
    psi = s.psi;
    V = s.V;
    dx = s.dx; dt = s.dt;
    % Finite difference Hamiltonian
    lap = zeros(1, s.N);
    lap(2:end-1) = (psi(3:end) - 2*psi(2:end-1) + psi(1:end-2)) / dx^2;
    H_psi = -0.5 * lap + V .* psi;
    s.psi = psi - 1j * H_psi * dt;
    s.psi = s.psi / sqrt(sum(abs(s.psi).^2) * dx);
end

function schrodinger_draw(ax, s)
    prob = abs(s.psi).^2;
    plot(ax, s.x, prob, 'b-', 'LineWidth', 2);
    fill(ax, s.x, s.V / 20, 'r', 'Alpha', 0.2); 
    title(ax, 'Quantum Tunneling: Probability Density |\psi|^2');
    ylim(ax, [0, 1.2]);
end

disp('Launching Quantum Simulation...');
simulate('algorithm', 'step', @schrodinger_step, 'draw', @schrodinger_draw, 'state', state);

disp('Quantum Mechanics Suite Complete.');
