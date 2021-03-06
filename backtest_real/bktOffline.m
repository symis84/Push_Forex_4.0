classdef bktOffline < handle
    
    properties
        nData
        starthisData
        newHisData
        iCloseActTimeScale
        iCloseNewTimeScale
        iOpenNewTimeScale
        stopL
        takeP
        outputBktOffline
        performance
        performanceDistribution
        timeSeriesProperties
    end
    
    methods
        
        function [obj] = spin(obj,nameAlgo,cross,nData_,histName,actTimeScale, ...
                newTimeScale,transCost,initialStack,leverage,plotPerformance,plotPerDistribution)
            
            %
            % DESCRIPTION:
            % -------------------------------------------------------------
            % This function runs the offline backtest on given historical data
            %
            % INPUT parameters:
            % -------------------------------------------------------------
            % nameAlgo:                 nome dell'algoritmo che usi
            % cross:                    ad es 'EURUSD'
            % nData:                    numero di dati in input di storico per ciclo
            % histName:                 nome dello storico, es: 'nome_storico.csv'
            % actTimeScale:             scala temporale dello storico in input
            % newTimeScale:             scala temporale su cui vuoi lavorare (in minuti)
            % transCost:                costo dello spread in pips, ad es: 1
            % initialStack:             capitale iniziale, ad es: 10000
            % leverage:                 la leva che usi, es: 10
            % plotPerformance:          1 se vuoi plottare le perfomance
            % plotPerDistribution:      1-microanalisi 2-macroanalisi 3-pattern ritorni
            %                           4-plot operazioni su storico 5-plotta tutto
            %
            % OUTPUT parameters:
            % -------------------------------------------------------------
            %starthisData
            % newHisData
            % iCloseActTimeScale
            % iCloseNewTimeScale
            % iOpenNewTimeScale
            % stopL
            % takeP
            % outputBktOffline
            % performance
            % performanceDistribution
            %
            % EXAMPLE of use:
            % -------------------------------------------------------------
            % clear all; bkt_Algo_002=bktOffline
            % bkt_Algo_002=bkt_Algo_002.spin('Algo_002_leadlag','EURUSD',100,'EURUSD_2012_2015.csv',1,30,1,10000,10,1,5)
            %
            % NOTE
            % -------------------------------------------------------------
            % per salvare lo storico:   dlmwrite('EURUSD_2012_2015.csv', data, '-append') ;
            %
            
            obj.nData=nData_;
            
            hisData = csvread(histName);
            [r,c] = size(hisData);
            startingOperation = 0;
            openValueReal = 0;
            indexOpen = 0;
            indexClose = 0;
            k = 0;
            
            % includi colonna delle date se non esiste nel file di input
            if c == 5
                
                hisData(1,6) = datenum('01/01/2015 00:00', 'mm/dd/yyyy HH:MM');
                
                for j = 2:r;
                    
                    hisData(j,6) = hisData(1,6) + ( (actTimeScale/1440)*(j-1) );
                    
                end
                
            end
            
            obj.starthisData=hisData;
            
            % riscala temporalmente se richiesto
            if newTimeScale > 1
                
                expert = TimeSeriesExpert_11;
                expert.rescaleData(hisData,actTimeScale,newTimeScale)
                
                obj.newHisData(:,1) = expert.openVrescaled;
                obj.newHisData(:,2) = expert.maxVrescaled;
                obj.newHisData(:,3) = expert.minVrescaled;
                obj.newHisData(:,4) = expert.closeVrescaled;
                obj.newHisData(:,5) = expert.volrescaled;
                obj.newHisData(:,6) = expert.openDrescaled;
                
            else
                
                obj.newHisData = hisData;
                
            end
            
            lhisData = length(hisData);
            lnewHisData = length(obj.newHisData);
            direction = zeros(floor(lnewHisData/2), 1);
            openingPrice = zeros(floor(lnewHisData/2), 1);
            closingPrice = zeros(floor(lnewHisData/2), 1);
            openingDateNum = zeros(floor(lnewHisData/2), 1);
            closingDateNum = zeros(floor(lnewHisData/2), 1);
            nCandelotto = zeros(floor(lnewHisData/2), 1);
            lots = zeros(floor(lnewHisData/2), 1);
            jC = zeros(floor(lnewHisData/2), 1);  % index j close
            iC = zeros(floor(lnewHisData/2), 1);   % index i close
            iO = zeros(floor(lnewHisData/2), 1);   % index i open
            SL = zeros(floor(lnewHisData/2), 1);   % stop loss
            TP = zeros(floor(lnewHisData/2), 1);   % take profit
            
            ltimeSeriesproperties=floor(lhisData/newTimeScale)-(obj.nData*newTimeScale);
            obj.timeSeriesProperties=zeros(ltimeSeriesproperties,3);
            matrix=zeros(obj.nData+1, 6);
            
            
            % ---  da qui inizia il core dello spin ---
            tic
            
            % l'indice i � sui dati alla new time scale
            for i = obj.nData:lnewHisData
                
                indexNewHisData=i-(obj.nData-1);
                matrix(1:obj.nData,:) = obj.newHisData(indexNewHisData:i,:);
                newTimeScalePoint=1; % controlla se ho dei nuovi dati sulla newTimeScale
                k=k+1; % serve solo nel calcolo della probabilit� di mean reversion etc...
                
                % l'indice j � sui dati al minuto (alla time scale pi� veloce)
                for j = 1:newTimeScale
                    
                    indexHisData=i*newTimeScale+j-1;
                    
                    % check se ho sforato oltre l'ultimo punto dello storico
                    if indexHisData > lhisData
                        break
                    end
                    
                    % se nn ho un buco NaN nello storico...
                    if isfinite(hisData(indexHisData,1))
                        
                        matrix(end,:) = hisData(indexHisData,:);
                        [oper, openValue, closeValue, stopLoss, takeProfit, valueTp, st] = Algo_002_leadlag(matrix,newTimeScalePoint,openValueReal);
                        
                        newState{1} = oper;
                        newState{2} = openValue;
                        newState{3} = closeValue;
                        newState{4} = stopLoss;
                        newState{5} = takeProfit;
                        newState{6} = valueTp;
                        
                        % calcola probabilit� di mean reversion etc 
                        a=st.HurstExponent;
                        b=st.pValue;
                        c=st.halflife;
                        if newTimeScalePoint && k>1;
                            obj.timeSeriesProperties(k-1,1)=a;
                            obj.timeSeriesProperties(k-1,2)=b;
                            obj.timeSeriesProperties(k-1,3)=c;
                        end
                        
                        newTimeScalePoint=0;
                        updatedOperation = newState{1};
                        
                        %opening
                        if abs(updatedOperation) > 0 && startingOperation == 0 
                            
                            openValueReal             = newState{2};
                            startingOperation         = newState{1};
                            
                            indexOpen = indexOpen + 1;
                            iO(indexOpen)=i;
                            SL(indexOpen)=stopLoss;
                            TP(indexOpen)=takeProfit;

                            display(['indexOpen =' num2str(indexOpen)]);
                            display(['i Open =' num2str(i)]);
                            display(['startingOperation =' num2str(startingOperation)]);
                            
                            direction(indexOpen)      = newState{1};
                            openingPrice(indexOpen)   = newState{2};                            
                            openingDateNum(indexOpen) = obj.newHisData(i,6);
                            lots(indexOpen)           = 1;
                        
                        % closing
                        elseif updatedOperation == 0 && abs(startingOperation) > 0 
                            
                            openValueReal             = 0;
                            
                            jC(indexOpen)=indexHisData;
                            iC(indexOpen)=i;
                            nCandelotto(indexOpen) = i;
                            indexClose = indexClose + 1;
                            closingPrice(indexOpen) = newState{3};
                            closingDateNum(indexOpen) = obj.newHisData(i,6);
                            display(['closeValue =' num2str(closeValue)]);
                            startingOperation = 0;
                            display('operation closed');
                            display(['i Close =' num2str(i)]);
                            
                        end
                        
                    end
                    
                end
                
            end
            
            toc
            
            direction = direction(1:indexClose);
            openingPrice = openingPrice(1:indexClose);
            openingDateNum = openingDateNum(1:indexClose);
            closingDateNum = closingDateNum(1:indexClose);
            lots = lots(1:indexClose);
                      
            jC=jC(1:indexClose);
            iC=iC(1:indexClose);
            iO=iO(1:indexClose);
            SL=SL(1:indexClose);
            TP=TP(1:indexClose);
            
            l = length(direction);
            
            obj.iCloseActTimeScale=jC;
            obj.iCloseNewTimeScale=iC;
            obj.iOpenNewTimeScale=iO;
            obj.stopL=SL;
            obj.takeP=TP;
            
            obj.outputBktOffline = zeros(l,8);
            
            obj.outputBktOffline(:,1) = nCandelotto(1:l);           % index of stick
            obj.outputBktOffline(:,2) = openingPrice(1:l);          % opening price
            obj.outputBktOffline(:,3) = closingPrice(1:l);          % closing price
            obj.outputBktOffline(:,4) = (closingPrice(1:l) ...
                - openingPrice(1:l)) .* direction(1:l);             % returns
            obj.outputBktOffline(:,5) = direction(1:l);             % direction
            obj.outputBktOffline(:,6) = ones(l,1);                  % real
            obj.outputBktOffline(:,7) = openingDateNum;             % opening date in day to convert use: d2=datestr(outputDemo(:,2), 'mm/dd/yyyy HH:MM')
            obj.outputBktOffline(:,8) = closingDateNum;             % closing date in day to convert use: d2=datestr(outputDemo(:,2), 'mm/dd/yyyy HH:MM')
            obj.outputBktOffline(:,9) = lots;                       % lots setted for single operation
            
%             obj.timeSeriesProperties(:,1)=st.HurstExponent;
%             obj.timeSeriesProperties(:,1)=st.pValue;
%             obj.timeSeriesProperties(:,1)=st.halflife;
            
            p = Performance_05;
            obj.performance = p.calcSinglePerformance(nameAlgo,'bktWeb',cross,newTimeScale,transCost,initialStack,leverage,obj.outputBktOffline,plotPerformance);
            pD = PerformanceDistribution_04;
            obj.performanceDistribution = pD.calcPerformanceDistr(nameAlgo,'bktWeb',cross,obj.nData,newTimeScale,transCost,obj.outputBktOffline,obj.timeSeriesProperties,obj.starthisData,obj.newHisData,15,10,10,plotPerDistribution);
            
        end
        
    end
    
end


