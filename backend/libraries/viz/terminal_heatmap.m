function terminal_heatmap(M, h, w)
    % TERMINAL_HEATMAP Create an ASCII heatmap using common terminal characters
    if nargin < 2 || isempty(h), h = 15; end
    if nargin < 3 || isempty(w), w = 40; end
    
    try
        % Use the high-performance Python ASCII renderer
        result = unilab_ascii_heatmap(M, h, w);
        disp(result);
    catch err
        disp(['Error in terminal_heatmap: ', err.message]);
    end
end
