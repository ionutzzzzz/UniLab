function terminal_heatmap(M, h, w)
    % TERMINAL_HEATMAP Create an ASCII heatmap using common terminal characters
    if nargin < 2 || isempty(h), h = 15; end
    if nargin < 3 || isempty(w), w = 40; end
    
    if is_web()
        terminal_heatmap_hd(M);
    else
        try
            % Use the high-performance Python ASCII renderer
            result = unilab_ascii_heatmap(M, h, w);
            disp(result);
        catch err
            % Fallback to HD heatmap if ASCII fails
            terminal_heatmap_hd(M);
        end
    end
end
