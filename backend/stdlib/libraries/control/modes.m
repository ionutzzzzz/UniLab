function mlist = modes(H)
    if nargin < 1, H = []; end
    pols = pole(H);
    syms t;
    mlist = [];
    
    processed = false(size(pols));

    for k = 1 : length(pols)
        if processed(k)
            continue;
        end

        p = pols(k);

        if isreal(p)
            current_mode = exp(p * t);
            mlist = [mlist; current_mode];
            processed(k) = true;
        else
            sigma = real(p);
            omega = abs(imag(p));
            
            current_mode = exp(sigma * t) * sin(omega * t);
            mlist = [mlist; current_mode];
            
            conj_idx = find(abs(pols - conj(p)) < 1e-6 & ~processed, 1);
            if ~isempty(conj_idx)
                processed(conj_idx) = true;
            end
            processed(k) = true;
        end
    end
end