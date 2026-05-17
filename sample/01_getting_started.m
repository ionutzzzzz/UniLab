disp('🌟 UniLab: Getting Started');
disp('==========================');

% 1. Constants & Booleans
disp('--- 1. Native Constants ---');
disp(['Pi: ', num2str(pi)]);
disp(['Infinity: ', num2str(inf)]);
disp(['Boolean True: ', num2str(true)]);
disp(['Machine Epsilon: ', num2str(eps)]);

% 2. Matrix Operations
disp(' ');
disp('--- 2. Matrix Operations ---');
A = [1 2; 3 4];
B = eye(2);
C = A * B;
disp('Matrix A:'); disp(A);
disp('A * eye(2):'); disp(C);

% 3. Anonymous Functions
disp(' ');
disp('--- 3. Anonymous Functions ---');
f = @(x, y) sqrt(x.^2 + y.^2);
result = f(3, 4);
disp(['Hypotenuse (3, 4) = ', num2str(result)]);

% 4. Auto-Help Feature
disp(' ');
disp('--- 4. Help System ---');
disp('Tip: You can now type any function name without parentheses');
disp('to see its documentation. Example: >> plot');

disp(' ');
disp('Getting Started Complete.');
