disp('⚙️ UniLab: Control Theory & System Analysis');
disp('===========================================');

% 1. Plant Modeling
disp('--- 1. Transfer Function Definition ---');
% Plant G(s) = 1 / (s^2 + 2s + 1)
G = tf([1], [1, 2, 1]);
disp('Plant G(s):');
disp(G);

% 2. Closed-Loop Feedback
disp(' ');
disp('--- 2. Closed-Loop Analysis ---');
% Controller H(s) = 1 (Unity feedback)
H = tf([1], [1]);
sys_cl = feedback(G, H);
disp('Closed-Loop System:');
disp(sys_cl);

% 3. Stability: Routh-Hurwitz
disp(' ');
disp('--- 3. Stability ---');
routh_table([1, 2, 2]);

% 4. Frequency Response
disp(' ');
disp('--- 4. Frequency Domain ---');
disp('Opening Bode Plot Window...');
bode(G);
title('Frequency Response of G(s)');

% 5. Step Response
disp(' ');
disp('--- 5. Time Domain ---');
step(sys_cl);
title('Unit Step Response (Closed-Loop)');

disp('Analysis Complete.');
