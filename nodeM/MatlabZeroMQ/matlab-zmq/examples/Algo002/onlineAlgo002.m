function [topicPub,messagePub] = onlineAlgo002(topicSub,messageSub)

persistent matrix;
persistent newTimeScalePoint;
persistent startingOperation;
persistent openValueReal;
persistent trial;

nData=100;

indexOpen = 0;
indexClose = 0;
k=0;

if(isempty(matrix))
    matrix = zeros(nData+1,6);
end

if(isempty (openValueReal))
    openValueReal = 0;
end

listener1 = strcmp(topicSub,'TIMEFRAMEQUOTE@MT4@ACTIVTRADES@EURUSD@m30@v100');
listener2 = strcmp(topicSub,'TIMEFRAMEQUOTE@MT4@ACTIVTRADES@EURUSD@m1@v1');
listener3 = strcmp(topicSub,'MATLAB@111@EURUSD@STATUS');

if listener1 == 1
    newData = textscan(messageSub,'%d %d %d %d %d %s','Delimiter',','); % messageSub: open,max,min,close,volume,data
    matrix(1:end-1,1)= newData(:,1);
    matrix(1:end-1,2)= newData(:,2);
    matrix(1:end-1,3)= newData(:,3);
    matrix(1:end-1,4)= newData(:,4);
    matrix(1:end-1,5)= newData(:,5);
    matrix(1:end-1,6)=datenum(newData{6}(:),'mm/dd/yyyy HH:MM');
    newTimeScalePoint=1; % controlla se ho dei nuovi dati sulla newTimeScale
    
elseif listener2 == 1
    newData = textscan(messageSub,'%d %d %d %d %d %s','Delimiter',','); % messageSub: open,max,min,close,volume,data
    matrix(end,1)= newData(:,1);
    matrix(end,2)= newData(:,2);
    matrix(end,3)= newData(:,3);
    matrix(end,4)= newData(:,4);
    matrix(end,5)= newData(:,5);
    matrix(end,6)=datenum(newData{6}(:),'mm/dd/yyyy HH:MM');
    
elseif listener3 == 1
    newStatus = textscan(messageSub,'%d %s %d %d','Delimiter',','); % messageSub: status(1,-1),type(open,close),price,ticket
    status= newStatus(1);
    type= newStatus(2);
    price= newStatus(3);
    ticket= newStatus(4);
    
    open  = strcmp(type,'open');
    close = strcmp(type,'close');
    
    if open
        StatusOpen  = status;
        if StatusOpen == 1
            openValueReal = price ;
            text=strcat('MT4 opened the requested operation',num2str(ticket),'at the price',num2str(price));
            display (text);
            trial=1;
        elseif StatusOpen == -1
            display ('MT4 failed in opening the requested operation');
            openValueReal = -1 ;
            startingOperation = 0;
        end
    elseif close
        StatusClose = status;
        if StatusClose == 1
            text=strcat('MT4 closed the requested operation',num2str(ticket),'at the price',num2str(price));
            display (text);
        elseif StatusClose == -1
            text=strcat('MT4 failed in closing the operation',num2str(ticket));
            display (text);
            if trial < 5
                trial=trial+1;
                [topicPub,messagePub,startingOperation]=onlineClose(price,ticket,indexClose);
                text=strcat('Matlab trial #',num2str(trial),'to close the operation',num2str(ticket));
                display (text);
            end
        end
    end
    
    
    if listener1
        
        topicPub='';
        messagePub='';
        
    elseif listener2
        
        [oper, openValue, closeValue, stopLoss, takeProfit, valueTp, st] = Algo_002_leadlag(matrix,newTimeScalePoint,openValueReal);
        
        newState{1} = oper;
        newState{2} = openValue;
        newState{3} = closeValue;
        newState{4} = stopLoss;
        newState{5} = takeProfit;
        newState{6} = valueTp;
        
        newTimeScalePoint=0;
        updatedOperation = newState{1};
        
        a=st.HurstExponent;
        b=st.pValue;
        c=st.halflife;
        if newTimeScalePoint && k>1;
            timeSeriesProperties(k-1,1)=a;
            timeSeriesProperties(k-1,2)=b;
            timeSeriesProperties(k-1,3)=c;
        end
        
        if abs(updatedOperation) > 0 && startingOperation == 0
            % Opening request
            [topicPub,messagePub,startingOperation]=onlineOpen(oper,openValue,stopLoss,takeProfit,indexOpen);
            
            
        elseif updatedOperation == 0 && abs(startingOperation) > 0
            % Clcosing request
            [topicPub,messagePub,startingOperation]=onlineClose(closeValue,ticket,indexClose);
            
        end
        
    end
    
end


