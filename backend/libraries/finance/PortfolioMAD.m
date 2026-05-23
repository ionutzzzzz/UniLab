function obj = PortfolioMAD(varargin)
    % PORTFOLIOMAD Create a PortfolioMAD object structure
    
    obj = Portfolio(varargin{:});
    obj.Returns = [];
end
