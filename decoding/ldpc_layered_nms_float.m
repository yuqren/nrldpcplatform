% ----------------------------------------------------------------------------
% FUNCTION INFORMATION (c) 2024 Telecommunications Circuits Laboratory, EPFL
% ----------------------------------------------------------------------------
% name : ldpc_layered_nms_float
% description : layered NMS decoding algorithm
% ----------------------------------------------------------------------------

function [decode_bits, decode_itera] = ldpc_layered_nms_float(baseGraph, Z, itera, norm, LLRIn)

[H_rows, H_cols] = size(baseGraph);

QMem  = reshape(LLRIn, Z, H_cols);
RMem  = zeros(Z, H_rows*H_cols);
TMem  = zeros(Z, H_cols);
QSign = zeros(Z, H_cols);

for i_itera = 1 : itera
    TDFlag = 1;
    
    for i_rows = 1 : H_rows
        SynCheck = zeros(Z, 1);
        
        % Phase 1: MIN
        min1   = Inf * ones(Z, 1); 
        min2   = Inf * ones(Z, 1); 
        sign   = ones(Z, 1);      

        minIdx = zeros(Z, 1); 
        minVec = zeros(Z, 1);

        for i_cols = 1 : H_cols
            if baseGraph(i_rows, i_cols) == -1
                continue;
            end
            shiftNum = baseGraph(li_rows, i_cols);
            
            Qc = Rotation(QMem(:, i_cols), shiftNum, Z); 
            TMem(:, i_cols) = Qc - RMem(:, (i_rows-1)*H_cols + i_cols); 
            
            sign             = sign.*signOP(TMem(:, i_cols));
            TMemAbs          = abs(TMem(:, i_cols));
            QSign(:, i_cols) = signOP(Qc);
            
            for i_Z = 1 : Z
                if TMemAbs(i_Z) < min1(i_Z)
                    min2(i_Z)   = min1(i_Z);
                    min1(i_Z)   = TMemAbs(i_Z);
                    minIdx(i_Z) =  i_cols;
                elseif TMemAbs(i_Z) < min2(i_Z)
                    min2(i_Z)   = TMemAbs(i_Z);
                end
            end
        end
        
        % Phase 2: Q- and R-messages update
        for i_cols = 1 : H_cols
            if baseGraph(i_rows, i_cols) == -1
                continue;
            end
            shiftNum = baseGraph(i_rows, i_cols);
            
            for i_Z = 1 : Z
                if minIdx(i_Z) == i_cols
                    minVec(i_Z) = min2(i_Z);
                else
                    minVec(i_Z) = min1(i_Z);
                end
            end
            
            RMem(:, (i_rows-1)*H_cols + i_cols) = sign.*signOP(TMem(:, i_cols)).*(minVec*norm);
            Qtmp = TMem(:, i_cols) + RMem(:, (i_rows-1)*H_cols + i_cols);
            
            if sum(abs((Qtmp < 0) - (QSign(:, i_cols) < 0))) ~= 0
                TDFlag = 0;
            end
            SynCheck = xor(SynCheck, (Qtmp < 0));
            
            Qtmp = Rotation(Qtmp, Z - shiftNum, Z);
            QMem(:, i_cols) = Qtmp;
        end
        
        if sum(SynCheck) > 0
            TDFlag = 0;
        end
    end
    
    % check whether TDFlag == 1 for each iteration
    if TDFlag == 1
        break;
    end
end

decode_bits  = double(reshape(QMem, H_cols*Z, 1) < 0);
decode_itera = i_itera; 
end

function yOut = Rotation(yIn, shiftNum, Z)
    yOut = [yIn(shiftNum + 1 : Z); yIn(1 : shiftNum)];
end