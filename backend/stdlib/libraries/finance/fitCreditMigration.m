function trans_matrix = fitCreditMigration(data)
    % FITCREDITMIGRATION Generates transition matrices
    % data: N x 2 matrix of [start_rating, end_rating]
    num_ratings = max(max(data));
    trans_matrix = zeros(num_ratings, num_ratings);
    
    for i = 1:size(data, 1)
        start_r = data(i, 1);
        end_r = data(i, 2);
        trans_matrix(start_r, end_r) = trans_matrix(start_r, end_r) + 1;
    end
    
    % Normalize rows
    for i = 1:num_ratings
        row_sum = sum(trans_matrix(i, :));
        if row_sum > 0
            trans_matrix(i, :) = trans_matrix(i, :) / row_sum;
        end
    end
end
