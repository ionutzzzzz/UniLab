function val = richardson_extrapolation(G_h, G_h2, p)
    % RICHARDSON_EXTRAPOLATION Improve accuracy from two estimates
    % G_h: estimate with step h, G_h2: estimate with step h/2, p: order of accuracy
    val = G_h2 + (G_h2 - G_h) / (2^p - 1);
end
