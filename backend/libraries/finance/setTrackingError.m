function obj = setTrackingError(obj, benchmark, error_limit)
    % SETTRACKINGERROR Adds tracking error constraint
    
    obj.Constraints.Benchmark = benchmark;
    obj.Constraints.TrackingErrorLimit = error_limit;
end
