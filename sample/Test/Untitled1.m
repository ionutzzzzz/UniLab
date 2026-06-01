%% MATLAB Syntax Demonstration Script
clc;
clear;
close all;

disp('=== MATLAB Syntax Test ===');

%% Variables and Data Types
a = 10;
b = 3.14;
c = "Hello";
d = 'World';
e = true;

disp(a);
disp(b);
disp(c);
disp(d);
disp(e);

%% Arrays and Matrices
v = [1 2 3 4 5];
m = [1 2; 3 4];

disp(v);
disp(m);

%% Cell Arrays
cellArr = {1, 'text', [1 2 3]};
disp(cellArr);

%% Structures
person.name = 'John';
person.age = 30;
disp(person);

%% Arithmetic Operations
x = 5;
y = 2;

disp(x + y);
disp(x - y);
disp(x * y);
disp(x / y);
disp(x ^ y);

%% Logical Operations
disp(x > y);
disp(x < y);
disp(x == y);
disp(x ~= y);
disp((x > 0) && (y > 0));

%% If Statement
if x > y
    disp('x is greater');
elseif x == y
    disp('equal');
else
    disp('y is greater');
end

%% Switch Statement
value = 2;

switch value
    case 1
        disp('One');
    case 2
        disp('Two');
    otherwise
        disp('Other');
end

%% For Loop
for i = 1:5
    fprintf('For loop: %d\n', i);
end

%% While Loop
count = 1;
while count <= 3
    fprintf('While loop: %d\n', count);
    count = count + 1;
end

%% Try-Catch
try
    z = 1 / 0;
    disp(z);
catch ME
    fprintf('Error: %s\n', ME.message);
end

%% Anonymous Function
square = @(n) n.^2;
disp(square(5));

%% Function Handle
fh = @sin;
disp(fh(pi/2));

%% Vectorization
vec = 1:10;
disp(vec.^2);

%% Matrix Operations
A = rand(3);
B = rand(3);

C = A * B;
D = A .* B;

disp(C);
disp(D);

%% Indexing
disp(vec(3));
disp(A(2,3));

%% Colon Operator
disp(1:2:10);

%% String Operations
s1 = "MATLAB";
s2 = "Test";
disp(s1 + " " + s2);

%% Table
T = table([1;2;3], ["A";"B";"C"], ...
    'VariableNames', {'ID','Name'});
disp(T);

%% Plotting
figure;
plot(1:10, rand(1,10));
title('Syntax Test Plot');
xlabel('X');
ylabel('Y');
grid on;

%% Timing
tic;
pause(0.1);
elapsed = toc;
fprintf('Elapsed time: %.4f s\n', elapsed);

%% File I/O
filename = 'test_file.txt';

fid = fopen(filename, 'w');
fprintf(fid, 'Hello MATLAB\n');
fclose(fid);

fid = fopen(filename, 'r');
content = fread(fid, '*char')';
fclose(fid);

disp(content);

%% Local Function Call
result = addNumbers(10, 20);
disp(result);

disp('=== End of Test ===');

%% Local Function
function out = addNumbers(a, b)
    out = a + b;
end