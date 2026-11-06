function [sys] = frd(response, frequencies)
    % FRD Create a frequency response data model
    % In UniLab, this is simplified to a Transfer Function or a container
    if nargin < 1, response = []; end
    if nargin < 2, frequencies = []; end
    sys = struct('Response', response, 'Frequencies', frequencies, 'Type', 'FRD');
    disp('Note: FRD is implemented as a data struct in UniLab.');
end
