import numpy as np

def train_linear_model(X, y):
    """
    Simple linear regression stub for UniLab ML package.
    """
    # X = (N, M), y = (N, 1)
    # theta = (X^T * X)^-1 * X^T * y
    print("Training linear regression model...")
    X_b = np.c_[np.ones((len(X), 1)), X] # add bias
    theta_best = np.linalg.inv(X_b.T.dot(X_b)).dot(X_b.T).dot(y)
    return theta_best

def predict_linear(X, theta):
    X_b = np.c_[np.ones((len(X), 1)), X]
    return X_b.dot(theta)

class NeuralNet:
    def __init__(self, layers=[10, 5, 1]):
        self.layers = layers
        print(f"Initialized NeuralNet with layers: {layers}")
        
    def forward(self, x):
        print("Running forward pass...")
        return np.random.rand(1)
