function plot_nn(layers)
    % PLOT_NN Plots a neural network architecture
    % layers: vector of layer sizes, e.g., [4 8 8 2]
    
    python_code = sprintf('from backend.stdlib.packages.ml.visualizers.nn_vis import plot_neural_network; plot_neural_network(%s)', mat2str(layers));
    % In UniLab transpiler, we can't directly run arbitrary python via eval yet 
    % but we can add this function to runtime or as a built-in.
    
    % For now, I'll just assume plot_neural_network is available in the global scope 
    % if we import it in TranspilerEngine.
    
    plot_neural_network(layers);
end
