function h = capillary_action_height(gamma, theta, rho, g, r)
    h = (2 * gamma * cos(theta)) / (rho * g * r);
end
