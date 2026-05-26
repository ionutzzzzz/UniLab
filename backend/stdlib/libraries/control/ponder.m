function h = ponder(num, den, U)
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