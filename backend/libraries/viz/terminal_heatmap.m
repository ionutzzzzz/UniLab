function terminal_heatmap(M)
    try
        imagesc(M);
        colorbar;
        print('graph.png', '-dpng');
        disp('::GRAPHICAL_PLOT::graph.png');
    catch err
        disp(['Error in terminal_heatmap: ', err.message]);
    end
end
