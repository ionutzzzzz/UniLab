function terminal_heatmap(M)
    try
        imagesc(M);
        imagesc(M);
        colorbar;
        print('graph.jpg', '-djpg');
        disp('::GRAPHICAL_PLOT::graph.jpg');

    catch err
        disp(['Error in terminal_heatmap: ', err.message]);
    end
end
