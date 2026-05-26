function [Y] = power_analyze(nodes, branches)
    % POWER_ANALYZE Simplified Nodal Analysis builder
    % Returns Y-Bus matrix for a given set of branches
    % branches: [from, to, R, L, C] matrix
    
    num_nodes = max(max(branches(:, 1:2)));
    Y = zeros(num_nodes, num_nodes);
    
    for k = 1:size(branches, 1)
        f = branches(k, 1);
        t = branches(k, 2);
        r = branches(k, 3);
        l = branches(k, 4);
        c = branches(k, 5);
        
        % Simplified complex impedance at 50Hz for Y-Bus construction
        z = r + 1j * 2 * pi() * 50 * l;
        y_val = 1/z + 1j * 2 * pi() * 50 * c/2;
        
        if f > 0 && t > 0
            Y(f, f) = Y(f, f) + y_val;
            Y(t, t) = Y(t, t) + y_val;
            Y(f, t) = Y(f, t) - 1/z;
            Y(t, f) = Y(t, f) - 1/z;
        elseif f > 0
            Y(f, f) = Y(f, f) + y_val;
        elseif t > 0
            Y(t, t) = Y(t, t) + y_val;
        end
    end
end
