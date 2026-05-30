function out = image_brightness(img, offset)
    out = img + offset;
    out(out > 255) = 255;
    out(out < 0) = 0;
end