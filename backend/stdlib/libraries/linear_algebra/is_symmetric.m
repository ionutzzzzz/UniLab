function b = is_symmetric(M)
    b = all(all(M == M'));
end
