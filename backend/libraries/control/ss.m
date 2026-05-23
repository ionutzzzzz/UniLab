function [varargout] = ss(varargin)
    % SS Create state-space model or extract state-space matrices
    % sys = ss(A, B, C, D)
    % [A, B, C, D] = ss(sys)
    
    if nargout > 1
        % Matrix extraction mode
        if nargin == 1
            [A, B, C, D] = ssdata(varargin{1});
        else
            [A, B, C, D] = unilab_ssdata(unilab_ss(varargin{:}));
        end
        varargout = {A, B, C, D};
    else
        % Model creation mode
        sys = unilab_ss(varargin{:});
        varargout = {sys};
    end
end
