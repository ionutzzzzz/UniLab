function [sys] = append(varargin)
    % APPEND Append system models to form decoupled model
    % sys = append(sys1, sys2, ...)
    sys = unilab_append(varargin{:});
end
