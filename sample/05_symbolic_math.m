disp('📐 UniLab: Symbolic Calculus & Math Lab');
disp('========================================');

% 1. Algebraic Manipulation
disp('--- 1. Symbolic Algebra ---');
syms x y
expr1 = (x + y)^3;
disp('Expanded (x + y)^3:');
disp(expand(expr1));

expr2 = (x^2 - 1) / (x - 1);
disp('Simplified (x^2 - 1) / (x - 1):');
disp(simplify(expr2));

% 2. Calculus
disp(' ');
disp('--- 2. Derivatives & Limits ---');
d = diff(sin(x) * exp(x), x);
disp('d/dx [sin(x)*e^x]:');
disp(d);

L = limit(sin(x)/x, x, 0);
disp('limit sin(x)/x as x -> 0:');
disp(L);

% 3. Integral Transforms
disp(' ');
disp('--- 3. Laplace Transforms ---');
syms t s
f = t^2 * exp(-3*t);
F = laplace(f, t, s);
disp('Laplace Transform of t^2 * e^(-3t):');
disp(F);

f_inv = ilaplace(1/(s^2 + 4), s, t);
disp('Inverse Laplace of 1/(s^2 + 4):');
disp(f_inv);

disp('UniLab Session Complete.');
