% 60_image_character_extraction.m
% UniLab Image Processing: Character Feature Extraction for OCR

clear all;
close all;
clc;

disp('🖼️ UniLab Image Analysis & OCR Features');
disp('=======================================');

%% 1. Generate Synthetic Character (Letter 'L')
disp('--- 1. Generating Character Image ---');
img = zeros(20, 20);
% Vertical bar
img(4:16, 6:8) = 255;
% Horizontal bar
img(14:16, 6:14) = 255;

% Add noise
img = img + randn(20, 20) * 10;
img(img < 0) = 0; img(img > 255) = 255;

disp('Raw Character Image (Heatmap):');
heatmap(img);

%% 2. Binarization (Thresholding)
disp('--- 2. Adaptive Binarization ---');
% Using library thresholding
thresh_val = 128;
bw_img = image_threshold(img, thresh_val);

disp('Binarized Character:');
heatmap(bw_img);

%% 3. Grid-Based Feature Extraction
disp('--- 3. Extracting Structural Features ---');
% Divide image into a 4x4 grid and calculate occupancy (density)
grid_size = 5;
features = zeros(4, 4);

for i = 1:4
    for j = 1:4
        r_start = (i-1)*grid_size + 1;
        c_start = (j-1)*grid_size + 1;
        cell_data = bw_img(r_start:r_start+grid_size-1, c_start:c_start+grid_size-1);
        features(i, j) = sum(sum(cell_data)) / (grid_size^2);
    end
end

disp('Feature Vector (4x4 Occupancy Grid):');
disp(features);

%% 4. Character Recognition (Simple Matching)
disp('--- 4. Recognition Logic ---');
% Theoretical 'L' profile would have high density in col 2 and row 4
if features(4, 2) > 0.5 && features(2, 2) > 0.5 && features(4, 3) > 0.5
    disp('Classification Result: Likely Character "L"');
else
    disp('Classification Result: Unknown/Ambiguous');
end

figure;
imagesc(features);
colorbar;
title('Extracted 4x4 Feature Map');
xlabel('Grid Col'); ylabel('Grid Row');

disp('Image Analysis Showcase Complete.');
