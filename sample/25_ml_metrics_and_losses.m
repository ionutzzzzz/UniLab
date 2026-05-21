% 25_ml_metrics_and_losses.m
% Demonstrates advanced Machine Learning loss functions and distance metrics

disp('🤖 UniLab ML Metrics & Losses');
disp('=============================');

disp('--- 1. Evaluating a Classification Model ---');
y_true_cls = [1, 1, 0, 0, 1];
y_pred_probs = [0.99, 0.85, 0.10, 0.35, 0.70];
y_pred_svm = [1.5, 0.5, -1.2, -0.1, 0.8]; % SVM raw decision outputs

loss_bce = binary_cross_entropy(y_true_cls', y_pred_probs');
% Hinge loss expects targets to be {-1, 1}
y_true_hinge = y_true_cls * 2 - 1;
loss_hinge = hinge_loss(y_true_hinge', y_pred_svm');

fprintf('Binary Cross Entropy Loss: %.4f
', loss_bce);
fprintf('Hinge Loss (SVM Margin): %.4f
', loss_hinge);

disp('--- 2. Evaluating a Regression Model (Robustness) ---');
y_true_reg = [10.5, 12.1, 9.8, 15.0, 11.2];
y_pred_reg = [10.2, 12.0, 9.9, 11.0, 11.5]; % Model missed the outlier 15.0 completely

% Compare standard MSE vs Huber Loss (delta = 1.0)
l_mse = mse(y_true_reg', y_pred_reg');
l_huber = huber_loss(y_true_reg', y_pred_reg', 1.0);

fprintf('Mean Squared Error (Sensitive to outlier): %.4f
', l_mse);
fprintf('Huber Loss (Robust to outlier): %.4f
', l_huber);

disp('--- 3. NLP / Recommender Embeddings Similarity ---');
embed_A = [1.0, 0.5, -0.2, 2.1];
embed_B = [0.9, 0.4, 0.0, 2.0];
sim_cosine = cosine_similarity(embed_A, embed_B);
dist_euc = euclidean_distance(embed_A, embed_B);

fprintf('Cosine Similarity between Vector A and B: %.4f
', sim_cosine);
fprintf('Euclidean Distance between Vector A and B: %.4f
', dist_euc);
