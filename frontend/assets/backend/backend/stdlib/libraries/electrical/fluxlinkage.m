function [lambda] = fluxlinkage(i, table_i, table_lambda)
    % FLUXLINKAGE Evaluates magnetic flux linkage from a table
    % lambda = fluxlinkage(i, table_i, table_lambda)
    
    if nargin < 1, i = []; end
    if nargin < 2, table_i = []; end
    if nargin < 3, table_lambda = []; end
    lambda = interp1_custom(table_i, table_lambda, i, 'linear');
end
