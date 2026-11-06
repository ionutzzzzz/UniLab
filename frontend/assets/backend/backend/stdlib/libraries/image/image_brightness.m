function out = image_brightness(img, offset)
    if nargin < 1, img = []; end
    if nargin < 2, offset = []; end
    out = img + offset;
    out(out > 255) = 255;
    out(out < 0) = 0;
end