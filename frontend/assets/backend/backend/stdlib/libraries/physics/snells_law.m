function theta2 = snells_law(n1, theta1, n2)
    theta2 = asin((n1 / n2) * sin(theta1));
end