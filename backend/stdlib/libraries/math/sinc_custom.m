function y = sinc_custom(x)
    y = ones(size(x));
    idx = x ~= 0;
    y(idx) = sin(pi()*x(idx)) ./ (pi()*x(idx));
end
