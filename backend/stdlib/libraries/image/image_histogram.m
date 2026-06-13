function h = image_histogram(img)
    if nargin < 1, img = []; end
    h = zeros(1, 256);
    for i = 1:size(img, 1)
        for j = 1:size(img, 2)
            val = round(img(i, j)) + 1;
            if val >= 1 && val <= 256
                h(val) = h(val) + 1;
            end
        end
    end
end