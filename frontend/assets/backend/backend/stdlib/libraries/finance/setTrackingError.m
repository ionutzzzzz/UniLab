function obj = setTrackingError(obj, benchmark, error_limit)
    % SETTRACKINGERROR Adds tracking error constraint
    
    if nargin < 1, obj = []; end
    if nargin < 2, benchmark = []; end
    if nargin < 3, error_limit = []; end
    obj.Constraints.Benchmark = benchmark;
    obj.Constraints.TrackingErrorLimit = error_limit;
end
