function [lambda] = fluxlinkage(i, table_i, table_lambda)
    % FLUXLINKAGE Evaluates magnetic flux linkage from a table
    % lambda = fluxlinkage(i, table_i, table_lambda)
    
    lambda = interp1_custom(table_i, table_lambda, i, 'linear');
end
