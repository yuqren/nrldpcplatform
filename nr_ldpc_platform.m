% ----------------------------------------------------------------------------
% FUNCTION INFORMATION (c) 2024 Telecommunications Circuits Laboratory, EPFL
% ----------------------------------------------------------------------------
% name : nr_ldpc_platform
% description : decoding 5g-nr ldpc with various configurations
% ----------------------------------------------------------------------------

clear
rng(1);

% ----------------------------------------------------------------------------
% 5G LDPC codes configuration
% ----------------------------------------------------------------------------
TxRx.bgn         = 1;                 % base graph
TxRx.Z           = 384;               % lifting size
TxRx.CR          = 0.8;               % code rate
TxRx.punc        = 2;                 % number of punctured columns
TxRx.core        = 10;                % multi-core
TxRx.norm        = 3/4;               % \alpha in nms
TxRx.SNR         = 1;                 % 1 is Eb/N0
TxRx.SNRrange    = 3.65:0.05:4.25;    % snr points
TxRx.maxIteras   = 5;                 % maximum iterations
TxRx.ToolboxFlag = 0;                 % flag=1, runs mex file, otherwise runs Matlab toolbox

% simulation settings
TxRx.frame       = 1000;              % frames in one batch
TxRx.group       = 10;                % accelerate speed for mex file
TxRx.disp        = 1000;              % print results every TxRx.disp frames
TxRx.maxFrames   = 1e9;               % simulated frames
TxRx.errFrames   = 100;               % erroneous frames for each SNR value

% nr ldpc parameters
if TxRx.bgn == 1
    TxRx.Nb = 68; TxRx.Mb = 46; TxRx.Kb = 22; % fixed value for BG1
else
    TxRx.Nb = 52; TxRx.Mb = 42; TxRx.Kb = 10; % fixed value for BG2
end

TxRx.usedMb  = ceil(TxRx.Kb/TxRx.CR) - TxRx.Kb + TxRx.punc;
TxRx.K       = TxRx.Kb*TxRx.Z;
TxRx.M       = TxRx.usedMb*TxRx.Z;
TxRx.padding = (TxRx.K + TxRx.M - TxRx.Z*TxRx.punc) - ceil(TxRx.K/TxRx.CR);
TxRx.CRreal  = TxRx.K/(TxRx.K+TxRx.M-TxRx.padding-TxRx.Z*TxRx.punc);

% ----------------------------------------------------------------------------
% PCM generation and other preparations
% ----------------------------------------------------------------------------
bgRows       = TxRx.usedMb;
bgCols       = TxRx.usedMb + TxRx.Kb;
baseGraph    = getBG(TxRx.bgn, TxRx.Z, bgRows, bgCols);
bgVec        = reshape(baseGraph', 1, bgRows*bgCols);

H            = ldpcQuasiCyclicMatrix(TxRx.Z, baseGraph);
ldpcencoder  = comm.LDPCEncoder(H);  % returns the position of all non-zero elements to decrease memory
cfgLDPCDec   = ldpcDecoderConfig(H, 'norm-min-sum'); % toolbox configuration

% storages
errFrames    = zeros(1, length(TxRx.SNRrange));
errBits      = zeros(1, length(TxRx.SNRrange));
runFrames    = zeros(1, length(TxRx.SNRrange));
runIteras    = zeros(1, length(TxRx.SNRrange));

FER          = zeros(1, length(TxRx.SNRrange));
BER          = zeros(1, length(TxRx.SNRrange));
avgIteras    = zeros(1, length(TxRx.SNRrange));

xFullSeq     = zeros(size(H,2), TxRx.frame);

% -----------------------------------------------------------------------------------------------------------
% Start the simulation
% -----------------------------------------------------------------------------------------------------------
for i_run = 1 : TxRx.frame : TxRx.maxFrames
    % check the termination
    if errFrames(end) >= TxRx.errFrames
        disp(' '); disp(['Sim iteration running = ' num2str(runFrames(end))]);
        disp(['BGN = ' num2str(TxRx.bgn) ' N = ' num2str(TxRx.K+TxRx.M-TxRx.padding-TxRx.Z*TxRx.punc) ' K = ' num2str(TxRx.K) ' CR = ' num2str(TxRx.CRreal) ' Z = ' num2str(TxRx.Z) ' Itera = ' num2str(TxRx.maxIteras) ' Core = ' num2str(TxRx.core)]);
        disp(['EbN0 or SNR = ' num2str(TxRx.SNR)]);
        disp('Current FER, BER, average iterations, and error frames');
        disp(num2str([TxRx.SNRrange'  FER'  BER' avgIteras' errFrames'])); disp(' ');
    end

    % generate the source messages
    infoBits  = randi([0 1], TxRx.K, TxRx.frame);
    for i_frame = 1 : TxRx.frame
        xFullSeq(:, i_frame) = ldpcencoder(infoBits(:, i_frame)); % full codeword, length is (TxRx.KGraph + M)
    end

    xSentSeq = xFullSeq;

    % generate the noise
    noise = randn(size(xSentSeq));

    % check the termination
    if errFrames(end) >= TxRx.errFrames 
        break;
    end

    % sweep all SNR points
    for i_SNR = 1: length(TxRx.SNRrange)
        if errFrames(i_SNR) >= TxRx.errFrames
            continue;
        end

        runFrames(i_SNR) = runFrames(i_SNR) + TxRx.frame;

        if TxRx.SNR == 1
            sigma = 1/sqrt(2.0*TxRx.CRreal) * 10^(-TxRx.SNRrange(i_SNR)/20);
        else
            sigma = 1/sqrt(2.0) * 10^(-TxRx.SNRrange(i_SNR)/20);
        end

        % BPSK
        symbols  = 1 - 2*xSentSeq;
        waveform = symbols + noise * sigma;
        chOut    = 2*waveform / sigma^2;
        chOut(1:TxRx.Z*TxRx.punc + TxRx.padding, :) = 0; % rate-matching

        % decode group-wise
        if TxRx.ToolboxFlag == 0
            chOut      = reshape(chOut, size(chOut, 1)*size(chOut, 2)/TxRx.group, TxRx.group);
            rxcbs      = zeros(TxRx.group, size(chOut, 1));
            thisIteras = zeros(TxRx.group, 1);
            parfor i_group = 1:TxRx.group % self-defined mex file
                [rxcbs(i_group, :), thisIteras(i_group)] = ldpc_layered_nms_float_mex(bgVec, TxRx.norm, TxRx.Z, TxRx.maxIteras, bgRows, bgCols, TxRx.frame/TxRx.group, chOut(:, i_group)', 1:bgRows);
            end
        else
            rxcbs      = zeros(TxRx.frame, size(chOut, 1));
            thisIteras = zeros(TxRx.frame, 1);
            parfor i_frame = 1:TxRx.frame % Matlab toolbox
                [rxcbs(i_frame, :), thisIteras(i_frame)] = ldpcDecode(chOut(:, i_frame), cfgLDPCDec, TxRx.maxIteras, 'OutputFormat', 'whole', 'MinSumScalingFactor', TxRx.norm, 'Termination', 'early');
            end
        end

        rxcbs      = reshape(rxcbs', 1, size(rxcbs,1)*size(rxcbs,2));
        thisIteras = sum(thisIteras);

        runIteras(i_SNR) = runIteras(i_SNR) + thisIteras;
        rxcbs            = reshape(rxcbs, size(xFullSeq));
        rxcbsi           = rxcbs(1: TxRx.K, :);

        % compare the sent data with the decoded one
        for i_frame = 1: TxRx.frame
            if ~isequal(rxcbsi(:, i_frame), xFullSeq(1: TxRx.K, i_frame))
                errFrames(i_SNR) = errFrames(i_SNR) + 1;
                errBits(i_SNR)   = errBits(i_SNR) + sum(rxcbsi(:, i_frame) ~= xFullSeq(1: TxRx.K, i_frame));
            end
        end

        % Calculate the FER/BER/Itera
        FER = 1-(1-errFrames./runFrames).^TxRx.core;
        BER = errBits./(TxRx.K*runFrames);
        avgIteras = runIteras./runFrames;

        break;
    end

    % disp
    if  mod(i_run + TxRx.frame, TxRx.disp) == 1
        disp(' '); disp(['Sim iteration running = ' num2str(sum(runFrames))]);
        disp(['BGN = ' num2str(TxRx.bgn) ' N = ' num2str(TxRx.K+TxRx.M-TxRx.padding-TxRx.Z*TxRx.punc) ' K = ' num2str(TxRx.K) ' CR = ' num2str(TxRx.CRreal) ' Z = ' num2str(TxRx.Z) ' Itera = ' num2str(TxRx.maxIteras) ' Core = ' num2str(TxRx.core)]);
        disp(['EbN0 or SNR = ' num2str(TxRx.SNR)]);
        disp('Current FER, BER, average iterations, and error frames');
        disp(num2str([TxRx.SNRrange'  FER'  BER' avgIteras' errFrames'])); disp(' ');
    end

    if errFrames(end) >= TxRx.errFrames
        disp(' '); disp(['Sim iteration running = ' num2str(sum(runFrames))]);
        disp(['BGN = ' num2str(TxRx.bgn) ' N = ' num2str(TxRx.K+TxRx.M-TxRx.padding-TxRx.Z*TxRx.punc) ' K = ' num2str(TxRx.K) ' CR = ' num2str(TxRx.CRreal) ' Z = ' num2str(TxRx.Z) ' Itera = ' num2str(TxRx.maxIteras) ' Core = ' num2str(TxRx.core)]);
        disp(['EbN0 or SNR = ' num2str(TxRx.SNR)]);
        disp('Current FER, BER, average iterations, and error frames');
        disp(num2str([TxRx.SNRrange'  FER'  BER' avgIteras' errFrames'])); disp(' ');
        break;
    end
end
figure; semilogy(TxRx.SNRrange, FER, 'o-b', 'linewidth', 1); grid on; xlabel('Eb/N0'); ylabel('FER');
figure; semilogy(TxRx.SNRrange, BER, 'o-r', 'linewidth', 1); grid on; xlabel('Eb/N0'); ylabel('BER');

