function terminal_plot(y, x, h, w, type)
    if nargin < 2 || isempty(x), x = 1:length(y); end
    if nargin < 5 || isempty(type), type = 'line'; end
    
    try
        % Standard Octave plotting
        if strcmp(type, 'scatter')
            scatter(x, y);
        elseif strcmp(type, 'area')
            area(x, y);
        elseif strcmp(type, 'stairs')
            stairs(x, y);
        elseif strcmp(type, 'bar')
            bar(x, y);
        else
            plot(x, y);
        end
        grid on;
        
        % Save and notify engine
        print('graph.png', '-dpng');
        disp('::GRAPHICAL_PLOT::graph.png');
    catch err
        disp(['Error in terminal_plot: ', err.message]);
    end
end
