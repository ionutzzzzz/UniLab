import matplotlib.pyplot as plt
import numpy as np

def plot_neural_network(layers, title="Neural Network Architecture"):
    """
    Plots a simple neural network architecture.
    layers: list of integers representing the number of neurons in each layer.
    """
    layer_sizes = np.asarray(layers).flatten().astype(int)
    
    fig, ax = plt.subplots(figsize=(10, 8))
    
    n_layers = len(layer_sizes)
    v_spacing = 1.0 / max(layer_sizes)
    h_spacing = 1.0 / (n_layers - 1)
    
    # Nodes
    for n, layer_size in enumerate(layer_sizes):
        layer_top = v_spacing * (layer_size - 1) / 2.0
        for m in range(layer_size):
            circle = plt.Circle((n * h_spacing, layer_top - m * v_spacing), v_spacing / 4.0,
                               color='w', ec='k', zorder=4)
            ax.add_artist(circle)
            
    # Edges
    for n, (layer_size_a, layer_size_b) in enumerate(zip(layer_sizes[:-1], layer_sizes[1:])):
        layer_top_a = v_spacing * (layer_size_a - 1) / 2.0
        layer_top_b = v_spacing * (layer_size_b - 1) / 2.0
        for m in range(layer_size_a):
            for o in range(layer_size_b):
                line = plt.Line2D([n * h_spacing, (n + 1) * h_spacing],
                                  [layer_top_a - m * v_spacing, layer_top_b - o * v_spacing],
                                  c='k', alpha=0.5, lw=0.5)
                ax.add_artist(line)
                
    ax.set_aspect('equal')
    plt.axis('off')
    plt.title(title, fontsize=16, fontweight='bold')
    
    # Save using the UniLab runtime helper if it's available in the context
    # But since this is a standalone visualizer, we just use standard plt.savefig
    # or rely on the caller to handle it.
    
    # In UniLab context, we want to call _unilab_refresh_graph()
    try:
        from backend.core.runtime import _unilab_refresh_graph
        _unilab_refresh_graph()
    except ImportError:
        plt.savefig("nn_plot.jpg")
    
    return fig

if __name__ == "__main__":
    plot_neural_network([4, 6, 6, 2])
    plt.show()
