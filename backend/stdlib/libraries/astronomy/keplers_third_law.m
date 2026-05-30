function T = keplers_third_law(G, M, a)
    T = sqrt((4 * pi()^2 * a^3) / (G * M));
end
