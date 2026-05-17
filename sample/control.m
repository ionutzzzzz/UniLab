% Define two systems
G = tf([1], [1, -2, -1]);
H = tf([1], [1]);

% Interconnect them
sys_series = series(G, H);
sys_cl = feedback(G, H);

% Display Root Locus
rlocus(G);