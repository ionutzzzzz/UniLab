function [R_delta] = wye_to_delta(Ra, Rb, Rc)
    % WYE_TO_DELTA Convert Wye (Y) resistance network to Delta (Δ)
    % Ra, Rb, Rc are resistances from center to nodes
    % Returns [R12, R23, R31]
    
    sum_prod = Ra*Rb + Rb*Rc + Rc*Ra;
    R12 = sum_prod / Rc;
    R23 = sum_prod / Ra;
    R31 = sum_prod / Rb;
    
    R_delta = [R12, R23, R31];
end

function [R_wye] = delta_to_wye(R12, R23, R31)
    % DELTA_TO_WYE Convert Delta (Δ) resistance network to Wye (Y)
    % Returns [Ra, Rb, Rc]
    
    sum_r = R12 + R23 + R31;
    Ra = (R12 * R31) / sum_r;
    Rb = (R12 * R23) / sum_r;
    Rc = (R23 * R31) / sum_r;
    
    R_wye = [Ra, Rb, Rc];
end
