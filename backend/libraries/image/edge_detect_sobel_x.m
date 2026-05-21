function out = edge_detect_sobel_x(img)
    [rows, cols] = size(img);
    out = zeros(rows, cols);
    kernel = [-1 0 1; -2 0 2; -1 0 1];
    for i = 2:rows-1
        for j = 2:cols-1
            window = img(i-1:i+1, j-1:j+1);
            out(i, j) = sum(sum(window .* kernel));
        end
    end
end