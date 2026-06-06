class HelpGuide {
  final String title;
  final String content;
  final String topic;

  const HelpGuide({
    required this.title,
    required this.content,
    required this.topic,
  });
}

class GuidesData {
  static const List<HelpGuide> guides = [
    HelpGuide(
      title: 'Introduction to UniLab',
      topic: 'intro',
      content: '''
# Welcome to UniLab

UniLab is a high-performance integrated development environment (IDE) for scientific computing, simulation, and data analysis. It combines a MATLAB-compatible scripting language with a modern, high-performance runtime.

### Key Features:
* **Powerful Scripting:** MATLAB-compatible syntax with Python integration.
* **Interactive Simulations:** Build and run real-time simulations with custom UI controls.
* **Advanced Plotting:** High-quality 2D and 3D data visualization.
* **Matrix Engine:** Optimized linear algebra and numerical computations.

### Interface Overview:
1. **Ribbon Bar:** Access common tools and actions (Home, Plots, Apps, Editor).
2. **File Explorer:** Manage your scripts and data files (left panel).
3. **Editor:** Write and edit your scientific scripts with syntax highlighting.
4. **Workspace:** View variables, inspect properties, and browse plots (right panel).
5. **Console:** Interact directly with the engine and view output (bottom panel).
''',
    ),
    HelpGuide(
      title: 'Scripting Basics',
      topic: 'scripting',
      content: '''
# Scripting Basics

UniLab uses a syntax very similar to MATLAB, making it easy to transition from other scientific environments.

### Variables and Data Types:
```matlab
a = 10;              % Scalar
b = [1, 2, 3];       % Row vector
c = [4; 5; 6];       % Column vector
d = [1, 2; 3, 4];    % 2x2 Matrix
str = "Hello World"; % String
```

### Control Flow:
```matlab
% For loop
for i = 1:5
    disp(i);
end

% If statement
if x > 0
    disp('Positive');
elseif x < 0
    disp('Negative');
else
    disp('Zero');
end
```

### Functions:
```matlab
function result = my_add(x, y)
    result = x + y;
end
```
''',
    ),
    HelpGuide(
      title: 'Working with Matrices',
      topic: 'matrices',
      content: '''
# Working with Matrices

Matrices are the core of UniLab. Almost everything is treated as a matrix.

### Creation:
* `zeros(3,3)` - 3x3 matrix of zeros
* `ones(2,4)` - 2x4 matrix of ones
* `eye(5)` - 5x5 identity matrix
* `rand(4,4)` - 4x4 matrix of random numbers

### Operations:
```matlab
A = [1, 2; 3, 4];
B = [5, 6; 7, 8];

C = A + B;       % Addition
D = A * B;       % Matrix Multiplication
E = A .* B;      % Element-wise Multiplication
F = A';          % Transpose
G = inv(A);      % Inverse
[V, D] = eig(A); % Eigenvalues and Eigenvectors
```
''',
    ),
    HelpGuide(
      title: 'Data Visualization',
      topic: 'plotting',
      content: '''
# Data Visualization

UniLab provides powerful plotting tools to visualize your data.

### Basic 2D Plots:
```matlab
x = linspace(0, 10, 100);
y = sin(x);
plot(x, y);
title('Sine Wave');
xlabel('Time');
ylabel('Amplitude');
grid on;
```

### Multiple Plots:
```matlab
hold on;
plot(x, cos(x), 'r--');
legend('Sine', 'Cosine');
```

### 3D Surfaces:
```matlab
[X, Y] = meshgrid(-2:0.1:2, -2:0.1:2);
Z = X .* exp(-X.^2 - Y.^2);
surf(X, Y, Z);
```
''',
    ),
    HelpGuide(
      title: 'Interactive Simulations',
      topic: 'simulations',
      content: '''
# Interactive Simulations

One of UniLab's unique features is the ability to create interactive simulations with real-time UI controls.

### Creating Controls:
```matlab
% Create a slider to control a parameter
uislider('Frequency', 0.1, 10, 1, @(v) update_freq(v));

% Create a button
uibutton('Reset', @(v) reset_sim());
```

### Simulation Loop:
You can use the `pause` or `drawnow` commands within a loop to animate your results in real-time.

```matlab
t = 0;
dt = 0.05;
while true
    t = t + dt;
    y = sin(2 * pi * freq * t);
    plot_point(t, y);
    drawnow;
    pause(0.01);
end
```
''',
    ),
    HelpGuide(
      title: 'Optimization & Algorithms',
      topic: 'optimization',
      content: '''
# Optimization & Algorithms

UniLab includes several built-in algorithms for optimization and numerical analysis.

### Gradient Descent:
You can implement custom optimization loops easily.
```matlab
% Simple gradient descent for f(x) = x^2
x = 10;
lr = 0.1;
for i = 1:20
    grad = 2 * x;
    x = x - lr * grad;
    disp(['Step ', num2str(i), ': x = ', num2str(x)]);
end
```

### Signal Processing:
Use built-in functions for filtering and transforms.
```matlab
y = fft(x);          % Fast Fourier Transform
[b, a] = butter(4, 0.2); % Butterworth filter
filtered = filter(b, a, signal);
```

### Solving Equations:
```matlab
% Solve dy/dt = -2y
[t, y] = ode45(@(t, y) -2*y, [0 5], 1);
plot(t, y);
```
''',
    ),
    HelpGuide(
      title: 'Keyboard Shortcuts',
      topic: 'shortcuts',
      content: '''
# Keyboard Shortcuts

Master UniLab with these essential keyboard shortcuts for faster development.

### General:
* `Ctrl + P`: Open Command Palette / Quick Open
* `Ctrl + S`: Save active file
* `Ctrl + Shift + S`: Save As...
* `Ctrl + W`: Close active tab
* `Ctrl + \\`: Split editor view
* `Ctrl + B`: Toggle sidebar visibility

### Execution:
* `F5`: Run active script
* `Ctrl + Enter`: Run selected code or current line in console
* `Shift + Esc`: Stop execution

### Editor:
* `Ctrl + F`: Find
* `Ctrl + H`: Replace
* `Ctrl + /`: Toggle line comment
* `Alt + Up/Down`: Move line up/down
* `Ctrl + Space`: Trigger autocomplete
''',
    ),
    HelpGuide(
      title: 'Data Import & Export',
      topic: 'data',
      content: '''
# Data Import & Export

UniLab makes it easy to work with external data files.

### Importing Data:
1. **From UI:** Go to `Home > Import Data` or right-click in the File Explorer and select `Import`.
2. **From Script:**
```matlab
data = load('measurements.csv');
% Supports .mat, .csv, .json, and .txt
```

### Exporting Data:
* **Variables:** Right-click a variable in the Workspace and select `Export As...`.
* **Plots:** Use the `Export` button in the Plot Gallery to save as PNG, SVG, or PDF.
* **Scripts:** Go to `File > Export to Python` to transpile your UniLab script.

### Workspace Inspector:
Double-click any variable in the Workspace panel to open it in the Property Inspector for detailed analysis and manual editing.
''',
    ),
  ];
}
