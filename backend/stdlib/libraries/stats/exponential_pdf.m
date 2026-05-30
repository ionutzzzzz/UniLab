function p = exponential_pdf(x, lambda)
    p = lambda * exp(-lambda * x);
    p(x < 0) = 0;
end
