function row = pascal_triangle_row(n)
    % PASCAL_TRIANGLE_ROW Return the n-th row of Pascal's triangle
    if nargin < 1, n = []; end
    row = zeros(1, n + 1);
    for k = 0:n
        row(k + 1) = nchoosek_custom(n, k);
    end
end
