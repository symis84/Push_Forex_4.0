classdef RiskManager_01 < handle
    
    properties
        
        nameAlgo;
        origin;
        period;
        cross;
        freq;
        transCost;
        inputResultsMatrix;
        
    end
    
    
    methods
        %% VaR calculation
        
        function obj=VaR(obj,performance)
            
            timeframe1day=performance.ferialExReturns;

            nPDF=6;
            [xPDF,hPDF,~]=PDF(timeframe1day,min(timeframe1day),max(timeframe1day),nPDF);
            [hCDF]=CDF(hPDF);
            
            figure
            plot(xPDF,hCDF,'-k');
            hold on
            plot(xPDF,hPDF,'-or');
            
        end
        
        
    end
    
end
