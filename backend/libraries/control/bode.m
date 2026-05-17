function [mag, phase, w] = bode(sys, w)
    if nargin < 2, w = []; end
    [w, mag, phase] = unilab_bode(sys, w);
    if nargout == 0
        % Simplified text output for now if no args returned
        disp('Bode Plot (Magnitude and Phase arrays available via return values)');
    end
end