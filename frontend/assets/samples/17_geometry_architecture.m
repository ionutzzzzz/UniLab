% 17_geometry_architecture.m
% Demonstrates compound area and perimeter calculations for architecture

clear all;
clc;

disp('🏛️ UniLab Architectural Geometry');
disp('================================');

disp('--- Compound Building Footprint Analysis ---');
% Calculate the footprint area of a modern museum
% It consists of a large rectangular hall, an elliptical atrium, and a hexagonal pavilion.

rect_a = rectangle_area(120, 80);
hex_a = regular_hexagon_area(30); % 30m sides
ellipse_a = ellipse_area(40, 25);

total_area = rect_a + hex_a + ellipse_a;
fprintf('Museum Rectangular Hall Area: %.2f sq meters
', rect_a);
fprintf('Museum Elliptical Atrium Area: %.2f sq meters
', ellipse_a);
fprintf('Museum Hexagonal Pavilion Area: %.2f sq meters
', hex_a);
fprintf('Total Museum Footprint Area: %.2f sq meters
', total_area);

disp('--- Elliptical Roof Perimeter ---');
% Calculate the exact fencing needed using Ramanujan's approximation
P_ellipse = ellipse_perimeter_approx(40, 25);
fprintf('Fencing required for the elliptical atrium roof: %.2f meters
', P_ellipse);
