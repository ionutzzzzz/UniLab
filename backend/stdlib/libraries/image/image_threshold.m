function bw = image_threshold(img, thresh)
    if nargin < 1, img = []; end
    if nargin < 2, thresh = []; end
    bw = zeros(size(img));
    bw(img >= thresh) = 1;
end