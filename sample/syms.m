syms x y
expr = (x^2 + 2*x + 1) / (x + 1);
s = simplify(expr);
disp('Simplified:');
disp(s);

expr2 = (x + y)^3;
e = expand(expr2);
disp('Expanded:');
disp(e);

expr3 = sin(x)^2 + cos(x)^2;
s3 = simplify(expr3);
disp('Trig Identity:');
disp(s3);

d = diff(sin(x), x);
disp('Derivative:');
disp(d);
