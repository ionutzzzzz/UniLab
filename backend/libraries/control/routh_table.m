function RT = routh_table(coeff)
    n = length(coeff);
    num_cols = ceil(n/2);
    RT = zeros(n, num_cols);

    RT(1, :) = coeff(1:2:end);

    row2 = coeff(2:2:end);
    RT(2, 1:length(row2)) = row2;

    for i = 3:n
        for j = 1:num_cols-1
            a = RT(i-1, 1);
            
            if a == 0
                a = eps;
            end
            
            RT(i, j) = (RT(i-1, 1) * RT(i-2, j+1) - RT(i-2, 1) * RT(i-1, j+1)) / a;
        end
        
        if all(RT(i, :) == 0)
            fprintf('Row s^%d is a row of zeros. System has roots on the jw-axis.\n', n-i);
        end
    end

    n = length(RT);
    fprintf('\nRouth-Hurwitz Table:\n');
    fprintf('----------------------------\n');

    for i = 1:n
        fprintf('s^%d | ', n-i);
        
        for j = 1:size(RT, 2)
            fprintf('%8.3f ', RT(i, j));
        end
        fprintf('\n');
    end
    fprintf('----------------------------\n');

    first_col = RT(:,1);
    first_col_clean = first_col(abs(first_col) > 1e-10);
    sign_changes = sum(diff(sign(first_col_clean)) ~= 0);

    if sign_changes == 0
        fprintf('The system is Stable (0 sign changes).\n');
    else
        fprintf('The system is Unstable! Found %d sign changes.\n', sign_changes);
    end
end