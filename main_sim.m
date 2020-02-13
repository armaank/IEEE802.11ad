% generate frame, pass frame through awgn, decode frame

% to generate frame, read in .mat file of data (start w/ random data)
% next, scramble data w/ polynomial (test decode)
% find where gen. polynomial cfs are transmitted (if at all)

out = mcsParams(1)
n_octets = 3  % number of psdu data octets
data = logical(randi([0 1],672/2,1));
% [seq, seed] = datagen.scramblerSeq(length(psdu_tx));
% scramblerout = xor(psdu_tx, seq)
% descrambler = xor(scramblerout, seq)
% seq2 = datagen
% psdu_tx - descrambler
pcm = paritycheck.pcm(1/2);
M = 4; % Modulation order (QPSK)
pskMod = comm.PSKModulator(M,'BitInput',true);
pskDemod = comm.PSKDemodulator(M,'BitOutput',true,...
    'DecisionMethod','Approximate log-likelihood ratio');
pskuDemod = comm.PSKDemodulator(M,'BitOutput',true,...
    'DecisionMethod','Hard decision');
encData = codes.ldpc(data, pcm);
        modSig = pskMod(encData);
        demodSig = pskDemod(modSig);
        rxBits = codes.ldpc_decode(demodSig, pcm);
% n_frames = 2; % number of frames used to test BER
% snr_vec = [0:2:16]; % SNR values
% len_snr = length(snr_vec);
% % Initializing the BER vector 
% bervec = zeros(numIter,lenSNR);
% 
% % creating a simple AWGN channel
% awgnchan = comm.AWGNChanel('NoiseMethod', 'Variance', 'Variance',1);
% error_rate = comm.ErrorRate;
% 
% for ii=1:n_frames
%     for jj=1:len_snr
% 
%         % initializing error statistics vector to calculate BER
%         error_stats = zeros(1,3)
%         % Calculating the noise variance and converting EbNo to SNR with
%         % modificaitons to account for the error control coding
%         EsNo = SNR_Vec(j) + 10*log10(k); % CHANGE       
%         snrdB = EsNo + 10*log10(codeRate);  % CHANGE    
%         noiseVar = 1./(10.^(snrdB/10)); 
%         
%         % Adding the proper noise to the channel cooresponding to the SNR
%         awgnChannel.Variance = noiseVar;
%         
%         while errorStats(3) < 1e7
%             
%             % main simulation
%         
%             error_stats = error_rate(data, rxdata)
%         end
%         
%         bervec = error_stats(1);
%         reset(error_rate)
%         
%     end
% end
% 
% berVec=mean(berVec,1);
% 
% 
% 
% 
