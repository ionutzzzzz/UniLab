function mag = image_gradient_magnitude(img)
    gx = edge_detect_sobel_x(img);
    gy = edge_detect_sobel_y(img);
    mag = sqrt(gx.^2 + gy.^2);
end