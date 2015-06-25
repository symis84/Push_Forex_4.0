function bktOffline(nData)
    storico = readcsv('storico.csv');
    startingOperation=0;
   
for i=100:length(storico)

        newState = algo(storico(i-99:i,:));
        
        %risultato contiene [oper, openValue, closeValue, stopLoss, noLoose, valueTp, real]
        
        operation=
        if abs(oper)>1 && startingOperation==0
            startingOperation=newState{1};
            registra_apertura ( newState );
        elseif (chiusura ( newState ))
            registra_chiusura ( newState );
        end
end

% 
% for i = 100:(length(v)-120)
%    v1 = v(i-99:i,1) ;
%    v2 = v(i-99:i,2) ;
%    v3 = v(i-99:i,3) ;
%    v4 = v(i-99:i,4) ;
%    %v5 = v(i-99:i,5) ;
%    v5 = [4 5 6];
%    for j = (i-1)*60+1:i*60
%         value = vp(j,4);
%         maxValue = vp(j,2);
%         minValue = vp(j,3);
%         v4(end) = value;
%         memory = operation;
%         %v4Minuto = vp(j-7999:j,4);
%         %v2Minuto = vp(j-7999:j,2);
%         %v3Minuto = vp(j-7999:j,3);
%         lifeCicleNew(v1,v2,v3,v4,v5);
%         if(sign(memory) > sign(operation) || sign(memory) < sign(operation))
%             k = k+1;
%             operazioni(k,2) = value;
%             operazioni(k,1) = operation;
%         end 
%    end


% risultato e' un array che contiene diversi valori
% [17:49:48] Ivan Valeriani: tipo apertura, chiusura, direzione...

