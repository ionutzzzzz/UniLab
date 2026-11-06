import matplotlib.pyplot as plt
import numpy as np

def plot_neural_network(layers=None, title="Neural Network Architecture"):
    """
    Plots a professional neural network architecture.
    layers: list of integers representing the number of neurons in each layer.
    """
    layer_sizes = np.asarray(layers).flatten().astype(int)
    
    # Use a clean, tight layout
    fig, ax = plt.subplots(figsize=(12, 9))
    
    # Define pastel colors for layers
    colors = ['#A8D8EA', '#AA96DA', '#FCBAD3', '#BAE1FF', '#FFFFD2']
    
    n_layers = len(layer_sizes)
    # Adjust spacing based on network size
    v_spacing = 1.0 / max(layer_sizes)
    h_spacing = 1.2 / (n_layers - 1) if n_layers > 1 else 1.0
    
    # Calculate radius based on spacing
    radius = v_spacing / 3.0
    
    # Edges (Draw first so they are behind nodes)
    for n, (layer_size_a, layer_size_b) in enumerate(zip(layer_sizes[:-1], layer_sizes[1:])):
        layer_top_a = v_spacing * (layer_size_a - 1) / 2.0
        layer_top_b = v_spacing * (layer_size_b - 1) / 2.0
        
        # Adjust edge thickness and alpha based on density
        density = layer_size_a * layer_size_b
        lw = max(0.2, 2.0 / np.sqrt(density))
        alpha = max(0.1, 0.6 / np.sqrt(density))
        
        for m in range(layer_size_a):
            for o in range(layer_size_b):
                line = plt.Line2D([n * h_spacing, (n + 1) * h_spacing],
                                  [layer_top_a - m * v_spacing, layer_top_b - o * v_spacing],
                                  c='#888888', alpha=alpha, lw=lw, zorder=1)
                ax.add_artist(line)
                
    # Nodes
    for n, layer_size in enumerate(layer_sizes):
        layer_top = v_spacing * (layer_size - 1) / 2.0
        
        # Determine layer color
        if n == 0: color = colors[0] # Input
        elif n == n_layers - 1: color = colors[2] # Output
        else: color = colors[1] # Hidden
        
        for m in range(layer_size):
            circle = plt.Circle((n * h_spacing, layer_top - m * v_spacing), radius,
                               color=color, ec='#333333', lw=2, zorder=4)
            ax.add_artist(circle)
            
    ax.set_aspect('equal')
    plt.axis('off')
    
    # We set the title on the axis but UniLab's renderer will add it as text.
    # To avoid pixelated title in the image, we can keep it as metadata only.
    ax.set_title(title)
    
    # Adjust limits to ensure everything is visible
    ax.set_xlim(-radius*2, (n_layers-1)*h_spacing + radius*2)
    
    try:
        from backend.core.runtime import _unilab_refresh_graph
        _unilab_refresh_graph()
    except:
        plt.savefig("nn_plot.jpg", bbox_inches='tight')
    
    return fig

if __name__ == "__main__":
    plot_neural_network([4, 6, 6, 2])
    plt.show()
