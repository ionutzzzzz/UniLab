% Test parfor in Rust engine
disp('Starting parfor test...');
tic;
parfor i = 1:10
    disp(['Iteration ', num2str(i)]);
end
duration = toc;
disp(['Parfor test completed in ', num2str(duration), ' seconds.']);
