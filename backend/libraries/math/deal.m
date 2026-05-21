function varargout = deal(varargin)
    % DEAL Assign inputs to outputs
    % [A, B, C, ...] = deal(X) assigns X to all outputs
    % [A, B, C, ...] = deal(X, Y, Z, ...) assigns X to A, Y to B, etc.
    
    if nargin == 1
        varargout = cell(1, nargout);
        for i = 1:nargout
            varargout{i} = varargin{1};
        end
    else
        if nargin ~= nargout
            error('Number of inputs must match number of outputs in deal');
        end
        varargout = varargin;
    end
end
