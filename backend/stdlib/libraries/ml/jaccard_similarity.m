function sim = jaccard_similarity(u, v)
    % JACCARD_SIMILARITY Jaccard similarity between two binary vectors
    if nargin < 1, u = []; end
    if nargin < 2, v = []; end
    intersection = sum((u == 1) & (v == 1));
    union = sum((u == 1) | (v == 1));
    if union == 0, sim = 1; else, sim = intersection / union; end
end
