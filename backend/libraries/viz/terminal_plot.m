function terminal_plot(y, x, h, w, type)
    % TERMINAL_PLOT Create an ASCII plot using common terminal characters
    if nargin < 2 || isempty(x), x = 1:length(y); end
    if nargin < 3 || isempty(h), h = 20; end
    if nargin < 4 || isempty(w), w = 60; end
    if nargin < 5 || isempty(type), type = 'line'; end
    
    if is_web()
        terminal_plot_hd(y, x, h, w, type);
    else
        try
            % Use the high-performance Python ASCII renderer
            result = unilab_ascii_plot(y, x, h, w, type);
            disp(result);
        catch err
            % Fallback to HD plot if ASCII fails (will show as marker in terminal)
            terminal_plot_hd(y, x, h, w, type);
        end
    end
end
