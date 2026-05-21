function g = gray_code(n)
    % GRAY_CODE n XOR (n >> 1)
    g = bitxor_custom(n, floor(n / 2));
end

function r = bitxor_custom(a, b)
    % Simple bitwise XOR for integers
    r = 0;
    for i = 0:31
        ba = mod(floor(a / 2^i), 2);
        bb = mod(floor(b / 2^i), 2);
        if ba ~= bb
            r = r + 2^i;
        end
    end
end
