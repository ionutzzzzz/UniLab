function l = lucas_number(n)
    % LUCAS_NUMBER Calculate the n-th Lucas number
    % L_0 = 2, L_1 = 1, L_n = L_{n-1} + L_{n-2}
    if nargin < 1, n = []; end
    if n == 0, l = 2; return; end
    if n == 1, l = 1; return; end
    
    a = 2; b = 1;
    for i = 2:n
        temp = a + b;
        a = b;
        b = temp;
    end
    l = b;
end
