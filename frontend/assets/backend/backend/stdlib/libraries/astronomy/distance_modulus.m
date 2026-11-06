function mu = distance_modulus(m, M)
    % DISTANCE_MODULUS Difference between apparent and absolute magnitude
    if nargin < 1, m = []; end
    if nargin < 2, M = []; end
    mu = m - M;
end
