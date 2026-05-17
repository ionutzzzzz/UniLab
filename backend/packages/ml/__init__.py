import numpy as np
from collections import Counter

# --- Activation Functions ---

def sigmoid(x):
    return 1 / (1 + np.exp(-np.clip(x, -500, 500)))

def sigmoid_derivative(x):
    return x * (1 - x)

def relu(x):
    return np.maximum(0, x)

def relu_derivative(x):
    return (x > 0).astype(float)

def tanh(x):
    return np.tanh(x)

def tanh_derivative(x):
    return 1 - x**2

def softmax(x):
    e_x = np.exp(x - np.max(x, axis=-1, keepdims=True))
    return e_x / np.sum(e_x, axis=-1, keepdims=True)

# --- Preprocessing ---

class StandardScaler:
    def __init__(self, with_mean=True, with_std=True):
        self.with_mean = with_mean
        self.with_std = with_std
        self.mean = None
        self.std = None

    def fit(self, X):
        X = np.asarray(X)
        if self.with_mean: self.mean = np.mean(X, axis=0)
        if self.with_std: self.std = np.std(X, axis=0)
        if self.std is not None: self.std[self.std == 0] = 1.0
        return self

    def transform(self, X):
        X = np.asarray(X)
        if self.with_mean: X = X - self.mean
        if self.with_std: X = X / self.std
        return X

    def fit_transform(self, X):
        return self.fit(X).transform(X)

class MinMaxScaler:
    def __init__(self, feature_range=(0, 1)):
        self.feature_range = feature_range
        self.min = None
        self.max = None

    def fit(self, X):
        X = np.asarray(X)
        self.min = np.min(X, axis=0)
        self.max = np.max(X, axis=0)
        return self

    def transform(self, X):
        X = np.asarray(X)
        denom = self.max - self.min
        denom[denom == 0] = 1.0
        X_std = (X - self.min) / denom
        return X_std * (self.feature_range[1] - self.feature_range[0]) + self.feature_range[0]

    def fit_transform(self, X):
        return self.fit(X).transform(X)

class PolynomialFeatures:
    def __init__(self, degree=2, include_bias=True):
        self.degree = degree
        self.include_bias = include_bias

    def fit_transform(self, X):
        X = np.asarray(X)
        n_samples, n_features = X.shape
        out = [np.ones((n_samples, 1))] if self.include_bias else []
        for d in range(1, self.degree + 1):
            out.append(X**d)
        return np.hstack(out)

# --- Linear Models ---

class LogisticRegression:
    def __init__(self, lr=0.01, epochs=1000, alpha=0.01, penalty='l2', fit_intercept=True):
        self.lr = lr
        self.epochs = epochs
        self.alpha = alpha
        self.penalty = penalty
        self.fit_intercept = fit_intercept
        self.theta = None

    def fit(self, X, y):
        X = np.asarray(X)
        y = np.asarray(y).reshape(-1, 1)
        if self.fit_intercept: X = np.c_[np.ones((len(X), 1)), X]
        self.theta = np.zeros((X.shape[1], 1))
        for _ in range(self.epochs):
            z = X.dot(self.theta)
            h = sigmoid(z)
            reg_grad = np.zeros_like(self.theta)
            if self.penalty == 'l2': reg_grad = self.alpha * self.theta
            elif self.penalty == 'l1': reg_grad = self.alpha * np.sign(self.theta)
            gradient = (X.T.dot(h - y) + reg_grad) / len(y)
            if self.fit_intercept: gradient[0] -= reg_grad[0] / len(y)
            self.theta -= self.lr * gradient
        return self

    def predict_prob(self, X):
        if self.fit_intercept: X = np.c_[np.ones((len(X), 1)), X]
        return sigmoid(np.dot(X, self.theta))

    def predict(self, X, threshold=0.5):
        return (self.predict_prob(X) >= threshold).astype(int)

# --- Decision Trees & Ensembles ---

class DecisionNode:
    def __init__(self, feature_idx=None, threshold=None, left=None, right=None, value=None):
        self.feature_idx, self.threshold, self.left, self.right, self.value = feature_idx, threshold, left, right, value

class DecisionTree:
    def __init__(self, max_depth=10, min_samples_split=2, min_impurity_decrease=0.0, task='classification', criterion='gini', max_features=None):
        self.max_depth, self.min_samples_split, self.min_impurity_decrease = max_depth, min_samples_split, min_impurity_decrease
        self.task, self.criterion, self.max_features = task, criterion, max_features
        self.root = None

    def _impurity(self, y):
        m = len(y)
        if m == 0: return 0
        if self.task == 'regression': return np.mean((y - np.mean(y))**2)
        probs = [np.sum(y == c) / m for c in np.unique(y)]
        if self.criterion == 'entropy': return -sum(p * np.log2(p + 1e-9) for p in probs)
        return 1.0 - sum(p**2 for p in probs)

    def fit(self, X, y):
        X, y = np.asarray(X), np.asarray(y)
        self.n_features_ = X.shape[1]
        if self.max_features is None: self.max_features_ = self.n_features_
        elif self.max_features == 'sqrt': self.max_features_ = int(np.sqrt(self.n_features_))
        elif self.max_features == 'log2': self.max_features_ = int(np.log2(self.n_features_))
        else: self.max_features_ = int(self.max_features)
        self.root = self._grow_tree(X, y)
        return self

    def _grow_tree(self, X, y, depth=0):
        n_samples, n_labels = len(X), len(np.unique(y))
        if depth >= self.max_depth or n_labels == 1 or n_samples < self.min_samples_split:
            return DecisionNode(value=self._calculate_leaf_value(y))
        best_feat, best_thresh, best_gain = self._best_split(X, y)
        if best_feat is None or best_gain < self.min_impurity_decrease:
            return DecisionNode(value=self._calculate_leaf_value(y))
        left_idx = X[:, best_feat] <= best_thresh
        left = self._grow_tree(X[left_idx], y[left_idx], depth + 1)
        right = self._grow_tree(X[~left_idx], y[~left_idx], depth + 1)
        return DecisionNode(best_feat, best_thresh, left, right)

    def _best_split(self, X, y):
        best_gain, split_idx, split_thresh = -1, None, None
        feat_indices = np.random.choice(self.n_features_, min(self.max_features_, self.n_features_), replace=False)
        for feat_idx in feat_indices:
            thresholds = np.unique(X[:, feat_idx])
            for thresh in thresholds:
                gain = self._information_gain(y, X[:, feat_idx], thresh)
                if gain > best_gain: best_gain, split_idx, split_thresh = gain, feat_idx, thresh
        return split_idx, split_thresh, best_gain

    def _information_gain(self, y, X_column, thresh):
        parent_loss = self._impurity(y)
        l_idx, r_idx = X_column <= thresh, X_column > thresh
        if np.sum(l_idx) == 0 or np.sum(r_idx) == 0: return -1
        child_loss = (np.sum(l_idx)/len(y)) * self._impurity(y[l_idx]) + (np.sum(r_idx)/len(y)) * self._impurity(y[r_idx])
        return parent_loss - child_loss

    def _calculate_leaf_value(self, y):
        if len(y) == 0: return 0
        return Counter(y).most_common(1)[0][0] if self.task == 'classification' else np.mean(y)

    def predict(self, X):
        return np.array([self._traverse_tree(x, self.root) for x in np.asarray(X)])

    def _traverse_tree(self, x, node):
        if node.value is not None: return node.value
        return self._traverse_tree(x, node.left) if x[node.feature_idx] <= node.threshold else self._traverse_tree(x, node.right)

class RandomForest:
    def __init__(self, n_trees=10, max_depth=10, min_samples_split=2, max_features='sqrt', bootstrap=True, task='classification'):
        self.n_trees, self.max_depth, self.min_samples_split = n_trees, max_depth, min_samples_split
        self.max_features, self.bootstrap, self.task, self.trees = max_features, bootstrap, task, []

    def fit(self, X, y):
        X, y = np.asarray(X), np.asarray(y)
        for _ in range(self.n_trees):
            tree = DecisionTree(max_depth=self.max_depth, min_samples_split=self.min_samples_split, task=self.task, max_features=self.max_features)
            idx = np.random.choice(len(X), len(X), replace=True) if self.bootstrap else np.arange(len(X))
            tree.fit(X[idx], y[idx])
            self.trees.append(tree)
        return self

    def predict(self, X):
        tree_preds = np.array([tree.predict(X) for tree in self.trees])
        if self.task == 'classification': return np.array([Counter(tree_preds[:, i]).most_common(1)[0][0] for i in range(X.shape[0])])
        return np.mean(tree_preds, axis=0)

class GradientBoosting:
    def __init__(self, n_estimators=100, lr=0.1, max_depth=3, task='regression'):
        self.n_estimators, self.lr, self.max_depth, self.task, self.trees = n_estimators, lr, max_depth, task, []
        self.init_prediction = None

    def fit(self, X, y):
        X, y = np.asarray(X), np.asarray(y)
        self.init_prediction = np.mean(y) if self.task == 'regression' else np.log(np.mean(y)/(1-np.mean(y)+1e-9))
        curr_pred = np.full(y.shape, self.init_prediction)
        for _ in range(self.n_estimators):
            p_val = curr_pred if self.task == 'regression' else 1/(1+np.exp(-curr_pred))
            res = y.reshape(p_val.shape) - p_val
            tree = DecisionTree(max_depth=self.max_depth, task='regression')
            tree.fit(X, res.flatten())
            self.trees.append(tree)
            curr_pred += self.lr * tree.predict(X).reshape(curr_pred.shape)
        return self

    def predict(self, X):
        preds = np.full(X.shape[0], self.init_prediction)
        for tree in self.trees: preds += self.lr * tree.predict(X)
        return preds if self.task == 'regression' else (1/(1+np.exp(-preds)) >= 0.5).astype(int)

# --- Anomaly Detection ---

class IsolationForest:
    def __init__(self, n_estimators=100, max_samples='auto'):
        self.n_estimators = n_estimators
        self.max_samples = max_samples
        self.trees = []

    def fit(self, X):
        X = np.asarray(X)
        n_samples = X.shape[0]
        if self.max_samples == 'auto': self.max_samples_ = min(256, n_samples)
        else: self.max_samples_ = min(self.max_samples, n_samples)
        for _ in range(self.n_estimators):
            idx = np.random.choice(n_samples, self.max_samples_, replace=False)
            tree = DecisionTree(max_depth=int(np.ceil(np.log2(self.max_samples_))), task='regression')
            tree.fit(X[idx], np.random.rand(self.max_samples_))
            self.trees.append(tree)
        return self

    def predict(self, X): # Simplified: return random scores as structural placeholder
        return np.random.rand(len(X))

# --- Probabilistic & Kernel Models ---

class GaussianProcessRegressor:
    def __init__(self, alpha=1e-10):
        self.alpha = alpha
        self.X_train, self.y_train, self.K_inv = None, None, None

    def _kernel(self, x1, x2):
        sqdist = np.sum(x1**2, 1).reshape(-1, 1) + np.sum(x2**2, 1) - 2 * np.dot(x1, x2.T)
        return np.exp(-0.5 * sqdist)

    def fit(self, X, y):
        self.X_train, self.y_train = np.asarray(X), np.asarray(y).reshape(-1, 1)
        K = self._kernel(self.X_train, self.X_train) + self.alpha * np.eye(len(self.X_train))
        self.K_inv = np.linalg.inv(K)
        return self

    def predict(self, X):
        K_s = self._kernel(self.X_train, np.asarray(X))
        return K_s.T.dot(self.K_inv).dot(self.y_train).flatten()

class GaussianNB:
    def fit(self, X, y):
        X, y = np.asarray(X), np.asarray(y).flatten()
        self.classes, self.params = np.unique(y), []
        for c in self.classes:
            Xc = X[y == c]
            self.params.append({"mean": Xc.mean(axis=0), "var": Xc.var(axis=0)+1e-9, "prior": len(Xc)/len(X)})
        return self

    def predict(self, X):
        X, posteriors = np.asarray(X), []
        for p in self.params:
            prob = np.log(p["prior"]) + np.sum(-0.5*np.log(2*np.pi*p["var"]) - 0.5*(X-p["mean"])**2/p["var"], axis=1)
            posteriors.append(prob)
        return self.classes[np.argmax(posteriors, axis=0)]

class SVM:
    def __init__(self, lr=0.001, lambda_param=0.01, epochs=1000):
        self.lr, self.lambda_param, self.epochs, self.w, self.b = lr, lambda_param, epochs, None, 0
    def fit(self, X, y):
        X, y_ = np.asarray(X), np.where(np.asarray(y) <= 0, -1, 1)
        self.w = np.zeros(X.shape[1])
        for _ in range(self.epochs):
            for i, x_i in enumerate(X):
                if y_[i] * (np.dot(x_i, self.w) - self.b) >= 1: self.w -= self.lr * (2*self.lambda_param*self.w)
                else: self.w -= self.lr*(2*self.lambda_param*self.w - y_[i]*x_i); self.b -= self.lr*y_[i]
        return self
    def predict(self, X): return np.where(np.dot(np.asarray(X), self.w)-self.b >= 0, 1, 0)

# --- Clustering ---

class AgglomerativeClustering:
    def __init__(self, n_clusters=2):
        self.n_clusters = n_clusters

    def fit_predict(self, X):
        X = np.asarray(X)
        n = X.shape[0]
        clusters = [[i] for i in range(n)]
        while len(clusters) > self.n_clusters:
            min_d, pair = float('inf'), (0, 0)
            for i in range(len(clusters)):
                for j in range(i+1, len(clusters)):
                    d = np.min([np.linalg.norm(X[x1]-X[x2]) for x1 in clusters[i] for x2 in clusters[j]])
                    if d < min_d: min_d, pair = d, (i, j)
            new_c = clusters[pair[0]] + clusters[pair[1]]
            clusters.pop(pair[1]); clusters.pop(pair[0]); clusters.append(new_c)
        labels = np.zeros(n, dtype=int)
        for i, c in enumerate(clusters):
            for idx in c: labels[idx] = i
        return labels

class KMeans:
    def __init__(self, k=3, max_iters=100, init='k-means++', tol=1e-4):
        self.k, self.max_iters, self.init, self.tol, self.centroids = k, max_iters, init, tol, None

    def fit(self, X):
        X = np.asarray(X)
        if self.init == 'random': self.centroids = X[np.random.choice(len(X), self.k, replace=False)]
        else:
            self.centroids = [X[np.random.randint(len(X))]]
            for _ in range(1, self.k):
                dists = np.array([min([np.sum((x-c)**2) for c in self.centroids]) for x in X])
                self.centroids.append(X[np.random.choice(len(X), p=dists/dists.sum())])
            self.centroids = np.array(self.centroids)
        for _ in range(self.max_iters):
            labels = np.argmin(np.linalg.norm(X[:, np.newaxis] - self.centroids, axis=2), axis=1)
            new_c = np.array([X[labels==i].mean(axis=0) if np.any(labels==i) else self.centroids[i] for i in range(self.k)])
            if np.allclose(self.centroids, new_c, atol=self.tol): break
            self.centroids = new_c
        return self

    def predict(self, X):
        return np.argmin(np.linalg.norm(np.asarray(X)[:, np.newaxis] - self.centroids, axis=2), axis=1)

# --- Neural Network (Professional) ---

class NeuralNet:
    def __init__(self, layers=[2, 4, 1], activation='relu', optimizer='adam', dropout=0.0, init='he'):
        self.layers = np.asarray(layers).flatten().astype(int)
        self.weights, self.biases, self.optimizer, self.dropout_rate = [], [], optimizer, dropout
        funcs = {'relu': (relu, relu_derivative), 'tanh': (tanh, tanh_derivative), 'sigmoid': (sigmoid, sigmoid_derivative)}
        self.act_func, self.act_deriv = funcs.get(activation, funcs['sigmoid'])
        for i in range(len(self.layers)-1):
            limit = np.sqrt(2.0/self.layers[i]) if init=='he' else np.sqrt(1.0/self.layers[i])
            self.weights.append(np.random.randn(self.layers[i], self.layers[i+1])*limit)
            self.biases.append(np.zeros((1, self.layers[i+1])))
            
    def forward(self, x, training=True):
        self.activations, self.masks, curr_a = [x], [], x
        for i in range(len(self.weights)):
            z = np.dot(curr_a, self.weights[i]) + self.biases[i]
            curr_a = softmax(z) if i == len(self.weights)-1 and self.layers[-1] > 1 else self.act_func(z)
            if training and self.dropout_rate > 0 and i < len(self.weights)-1:
                mask = (np.random.rand(*curr_a.shape) > self.dropout_rate).astype(float)/(1.0-self.dropout_rate)
                curr_a *= mask
                self.masks.append(mask)
            else: self.masks.append(None)
            self.activations.append(curr_a)
        return curr_a
        
    def train(self, X, y, epochs=1000, lr=0.001, l1=0.0, l2=0.01):
        X, y = np.asarray(X), np.asarray(y).reshape(-1, 1 if len(y.shape)==1 or y.shape[1]==1 else y.shape[1])
        mw, vw, mb, vb = [np.zeros_like(w) for w in self.weights], [np.zeros_like(w) for w in self.weights], [np.zeros_like(b) for b in self.biases], [np.zeros_like(b) for b in self.biases]
        for t in range(1, epochs + 1):
            out = self.forward(X, training=True)
            deltas = [out - y]
            for i in range(len(self.weights)-1, 0, -1):
                d = deltas[0].dot(self.weights[i].T) * self.act_deriv(self.activations[i])
                if self.masks[i-1] is not None: d *= self.masks[i-1]
                deltas.insert(0, d)
            for i in range(len(self.weights)):
                gw = self.activations[i].T.dot(deltas[i])/len(X) + l2*self.weights[i] + l1*np.sign(self.weights[i])
                gb = np.mean(deltas[i], axis=0, keepdims=True)
                if self.optimizer == 'adam':
                    mw[i] = 0.9*mw[i] + 0.1*gw; vw[i] = 0.999*vw[i] + 0.001*(gw**2)
                    mb[i] = 0.9*mb[i] + 0.1*gb; vb[i] = 0.999*vb[i] + 0.001*(gb**2)
                    self.weights[i] -= lr*(mw[i]/(1-0.9**t))/(np.sqrt(vw[i]/(1-0.999**t))+1e-8)
                    self.biases[i] -= lr*(mb[i]/(1-0.9**t))/(np.sqrt(vb[i]/(1-0.999**t))+1e-8)
                else: self.weights[i] -= lr*gw; self.biases[i] -= lr*gb
            if t % (max(1, epochs//10)) == 0: print(f"Epoch {t}: loss = {np.mean(np.square(y-out)):.6f}")

    def predict(self, x): return self.forward(np.asarray(x), training=False)

# --- Metrics ---

def accuracy_score(y_true, y_pred): return np.mean(np.asarray(y_true).flatten() == np.asarray(y_pred).flatten())
def mean_squared_error(y_true, y_pred): return np.mean((np.asarray(y_true)-np.asarray(y_pred))**2)
def confusion_matrix(y_true, y_pred):
    y_t, y_p = np.asarray(y_true).flatten(), np.asarray(y_pred).flatten()
    cl = np.unique(np.concatenate([y_t, y_p]))
    cm = np.zeros((len(cl), len(cl)), dtype=int)
    for i, c1 in enumerate(cl):
        for j, c2 in enumerate(cl): cm[i,j] = np.sum((y_t==c1)&(y_p==c2))
    return cm
