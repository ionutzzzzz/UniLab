function obj = PortfolioCVaR(varargin)
    % PORTFOLIOCVAR Create a PortfolioCVaR object structure
    
    obj = Portfolio(varargin{:});
    obj.ProbabilityLevel = 0.95;
    obj.Returns = [];
end
