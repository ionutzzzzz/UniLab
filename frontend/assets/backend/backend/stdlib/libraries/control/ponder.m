function h = ponder(num, den, U)
    if nargin < 1, num = []; end
    if nargin < 2, den = []; end
    if nargin < 3, U = []; end
    Ha = tf(num, den);
    H = minreal(Ha);

    syms s t;
    [n, d] = tfdata(Ha, 'v');
    H = poly2sym(n, s) / poly2sym(d, s); 
    h = ilaplace(H * U);

    disp('Symbolic Transfer Function H(s):');
    disp(H);
    disp('Ponder Function h(t):');
    disp(h);
end