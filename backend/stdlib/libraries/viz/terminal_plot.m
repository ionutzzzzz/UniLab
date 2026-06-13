function terminal_plot(y, x, h, w, type)
    % TERMINAL_PLOT Create an ASCII plot using common terminal characters
    if nargin < 1, y = []; end
    if nargin < 2 || isempty(x), x = 1:length(y); end
    if nargin < 3 || isempty(h), h = 20; end
    if nargin < 4 || isempty(w), w = 60; end
    if nargin < 5 || isempty(type), type = 'line'; end
    
    if is_web()
        terminal_plot_hd(y, x, h, w, type);
    else
        try
            % Use the high-performance Python ASCII renderer for immediate terminal feedback
            result = unilab_ascii_plot(y, x, h, w, type);
            if ~isempty(result)
                disp(result);
            end
        catch err
            % Ignore ASCII failures if we have HD fallback
        end
        
        % Always call HD plot to ensure graph.png is updated and labels can be attached
        terminal_plot_hd(y, x, h, w, type);
    end
end
