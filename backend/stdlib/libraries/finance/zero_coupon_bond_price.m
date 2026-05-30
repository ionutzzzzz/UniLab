function p = zero_coupon_bond_price(par, r, t)
    % ZERO_COUPON_BOND_PRICE Price of a zero-coupon bond
    % p = par / (1 + r)^t
    p = par / (1 + r)^t;
end
