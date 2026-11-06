function out = image_contrast(img, factor)
    if nargin < 1, img = []; end
    if nargin < 2, factor = []; end
    out = factor * (img - 128) + 128;
    out(out > 255) = 255;
    out(out < 0) = 0;
end