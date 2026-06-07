% 50_image_processing_filters.m
% UniLab Image Processing: Computer Vision Filters

clear all;
close all;
clc;

disp('🖼️ UniLab Image Processing & CV');
disp('===============================');

disp('--- 1. Generating Synthetic Image ---');
% Create a 30x30 black image with a white square in the center
img = zeros(30, 30);
img(10:20, 10:20) = 255;

disp('Original Image (Matrix Heatmap):');
heatmap(img);

disp('--- 2. Box Blur Filter (Smoothing) ---');
% Apply 3x3 box blur twice sequentially for a stronger effect
blurred_img = box_blur_3x3(img);
blurred_img = box_blur_3x3(blurred_img);

disp('Blurred Image:');
heatmap(blurred_img);

disp('--- 3. Edge Detection (Sobel) ---');
% Compute gradient magnitude using Sobel operators
grad_mag = image_gradient_magnitude(img);

disp('Edge Detection (Gradient Magnitude):');
heatmap(grad_mag);

disp('--- 4. Image Histogram ---');
% Extract histogram distribution from the blurred image
hist_data = image_histogram(blurred_img);

figure;
plot(0:255, hist_data, 'b-', 'LineWidth', 2);
title('Image Histogram (Blurred Synthetic Image)');
xlabel('Pixel Intensity (0-255)'); ylabel('Frequency');
grid on;

disp('Image Processing operations complete.');