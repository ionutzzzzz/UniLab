function out = image_contrast(img, factor)
    out = factor * (img - 128) + 128;
    out(out > 255) = 255;
    out(out < 0) = 0;
end