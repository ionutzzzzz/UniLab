% 16_corporate_finance.m
% Demonstrates corporate finance ratio analysis and margin evaluations

disp('💼 UniLab Corporate Finance');
disp('===========================');

% Hypothetical Company Financials (e.g., Tech Startup)
revenue = 5000000;
cogs = 1800000;
op_income = 1200000;
net_income = 850000;
total_assets = 10000000;
equity = 6500000;
current_assets = 3000000;
current_liab = 1500000;

disp('--- DuPont Ratio Analysis ---');
gm = gross_margin(revenue, cogs);
om = operating_margin(op_income, revenue);
npm = net_profit_margin(net_income, revenue);
roa = return_on_assets(net_income=net_income, total_assets=total_assets);
roe = return_on_equity(net_income, equity);
cr = current_ratio(current_assets, current_liab);

fprintf('Gross Margin:       %.2f%%
', gm * 100);
fprintf('Operating Margin:   %.2f%%
', om * 100);
fprintf('Net Profit Margin:  %.2f%%
', npm * 100);
fprintf('Return on Assets:   %.2f%%
', roa * 100);
fprintf('Return on Equity:   %.2f%%
', roe * 100);
fprintf('Current Ratio:      %.2f
', cr);
