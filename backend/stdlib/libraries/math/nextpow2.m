function p = nextpow2(x)
    % NEXTPOW2 Next higher power of 2
    if x == 0
        p = 0;
    else
        p = ceil(log2(abs(x)));
    end
end
