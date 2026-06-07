function inv = image_invert(img, max_val)
    if nargin < 2; max_val = 255; end
    inv = max_val - img;
end