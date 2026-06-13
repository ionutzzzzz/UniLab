function [X, y] = make_blobs(n_samples, n_features, centers, cluster_std)
    % MAKE_BLOBS Generate isotropic Gaussian blobs for clustering
    % [X, y] = make_blobs(n_samples, n_features, centers, cluster_std)
    
    if nargin < 1, n_samples = []; end
    if nargin < 2, n_features = []; end
    if nargin < 4, cluster_std = 1.0; end
    if nargin < 3, centers = 3; end
    
    X = zeros(n_samples, n_features);
    y = zeros(n_samples, 1);
    
    samples_per_center = floor(n_samples / centers);
    
    for i = 1:centers
        start_idx = (i-1) * samples_per_center + 1;
        if i == centers
            end_idx = n_samples;
        else
            end_idx = i * samples_per_center;
        end
        
        center_pos = rand(1, n_features) * 10; % Random center position
        X(start_idx:end_idx, :) = center_pos + randn(end_idx - start_idx + 1, n_features) * cluster_std;
        y(start_idx:end_idx) = i;
    end
end
