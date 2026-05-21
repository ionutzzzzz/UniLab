function bw = image_threshold(img, thresh)
    bw = zeros(size(img));
    bw(img >= thresh) = 1;
end