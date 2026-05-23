function scorecard = creditscorecard()
    % CREDITSCORECARD Creates a baseline credit scorecard model
    scorecard = struct();
    scorecard.Model = 'Logistic';
    scorecard.BasePoints = 600;
    scorecard.PDO = 20;
    scorecard.PointsPerValue = struct();
end
