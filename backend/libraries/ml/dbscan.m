function [idx, core_pts] = dbscan(X, eps, min_pts)
    % DBSCAN Density-Based Spatial Clustering of Applications with Noise
    
    m = size(X, 1);
    idx = zeros(m, 1);
    core_pts = zeros(m, 1);
    cluster_id = 0;
    
    for i = 1:m
        if idx(i) ~= 0
            continue;
        end
        
        % Find neighbors
        neighbors = [];
        for j = 1:m
            if norm(X(i, :) - X(j, :)) <= eps
                neighbors = [neighbors, j];
            end
        end
        
        if length(neighbors) < min_pts
            idx(i) = -1; % Noise
        else
            cluster_id = cluster_id + 1;
            idx(i) = cluster_id;
            core_pts(i) = 1;
            
            % Expand cluster
            k = 1;
            while k <= length(neighbors)
                curr_p = neighbors(k);
                
                if idx(curr_p) == -1
                    idx(curr_p) = cluster_id;
                elseif idx(curr_p) == 0
                    idx(curr_p) = cluster_id;
                    
                    curr_neighbors = [];
                    for j = 1:m
                        if norm(X(curr_p, :) - X(j, :)) <= eps
                            curr_neighbors = [curr_neighbors, j];
                        end
                    end
                    
                    if length(curr_neighbors) >= min_pts
                        core_pts(curr_p) = 1;
                        % Merge neighbors uniquely
                        for j = 1:length(curr_neighbors)
                            if ~any(neighbors == curr_neighbors(j))
                                neighbors = [neighbors, curr_neighbors(j)];
                            end
                        end
                    end
                end
                k = k + 1;
            end
        end
    end
end
