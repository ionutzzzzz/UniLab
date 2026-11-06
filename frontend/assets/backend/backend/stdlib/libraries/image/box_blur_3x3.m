function out = box_blur_3x3(img)
    if nargin < 1, img = []; end
    [rows, cols] = size(img);
    out = zeros(rows, cols);
    for i = 2:rows-1
        for j = 2:cols-1
            out(i, j) = sum(sum(img(i-1:i+1, j-1:j+1))) / 9;
        end
    end
end