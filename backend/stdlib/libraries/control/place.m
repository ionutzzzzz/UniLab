function [K] = place(A, B, p)
    % PLACE Pole placement gain selection
    % K = place(A, B, p)
    K = unilab_place(A, B, p);
end
