syms t s x

expr = x^2 - 4;
factor(expr)

f = exp(-2*t);
disp('Function f(t):');
disp(f);

F = laplace(f, t, s);
disp('Laplace Transform F(s):');
disp(F);

f_inv = ilaplace(F, s, t);
disp('Inverse Laplace f(t):');
disp(f_inv);
