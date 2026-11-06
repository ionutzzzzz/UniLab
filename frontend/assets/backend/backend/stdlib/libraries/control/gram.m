function [G] = gram(sys, type)
    % GRAM Controllability and observability Gramians
    % G = gram(sys, type) where type is 'c' or 'o'
    if nargin < 1, sys = []; end
    if nargin < 2, type = 'c'; end
    G = unilab_gram(sys, type);
end
