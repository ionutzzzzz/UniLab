function terminal_plot(y, x, h, w, type)
    % TERMINAL_PLOT Create an ASCII plot using common terminal characters
    if nargin < 2 || isempty(x), x = 1:length(y); end
    if nargin < 3 || isempty(h), h = 20; end
    if nargin < 4 || isempty(w), w = 60; end
    if nargin < 5 || isempty(type), type = 'line'; end
    
    try
        % Use the high-performance Python ASCII renderer
        result = unilab_ascii_plot(y, x, h, w, type);
        disp(result);
    catch err
        disp(['Error in terminal_plot: ', err.message]);
    end
end
