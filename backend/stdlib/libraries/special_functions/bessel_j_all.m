function y = bessel_j_all(n, x)
    % BESSEL_J_ALL Bessel function J_n(x) for integer n
    if n == 0
        y = bessel_j0_approx(x, 10);
    elseif n == 1
        y = bessel_j1(x);
    else
        % Recursion: J_{n+1}(x) = (2n/x)J_n(x) - J_{n-1}(x)
        j_prev = bessel_j0_approx(x, 10);
        j_curr = bessel_j1(x);
        for i = 1:abs(n)-1
            j_next = (2*i / x) * j_curr - j_prev;
            j_prev = j_curr;
            j_curr = j_next;
        end
        y = j_curr;
        if n < 0 && mod(n, 2) ~= 0, y = -y; end
    end
end
