function phi_list = euler_totient_list(n)
    % EULER_TOTIENT_LIST Calculate Euler's totient function for all numbers up to n
    phi_list = 1:n;
    for i = 2:n
        if phi_list(i) == i
            for j = i:i:n
                phi_list(j) = phi_list(j) - phi_list(j) / i;
            end
        end
    end
end
