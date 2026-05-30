function [score] = r2_score(y_true, y_pred)
    % R2_SCORE Calculate the R-squared score
    % score = 1 - sum((y_true - y_pred).^2) / sum((y_true - mean(y_true)).^2)
    
    ss_res = sum((y_true - y_pred).^2);
    ss_tot = sum((y_true - mean(y_true)).^2);
    score = 1 - (ss_res ./ ss_tot);
end
