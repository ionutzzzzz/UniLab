function mag = image_gradient_magnitude(img)
    if nargin < 1, img = []; end
    gx = edge_detect_sobel_x(img);
    gy = edge_detect_sobel_y(img);
    mag = sqrt(gx.^2 + gy.^2);
end