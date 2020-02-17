%% Wireless link simulation for IEEE802.11 ad
clc;
clear;

%% BER Simulation

snr_vec = 0:2:16 % SNR values for BER curve
snr_len = length(snr_vec)
n_frames = 1; % number of iterations for the monte-carlo simulation
n_octets = 5 % number of data octets in PSDU 

MCS_idx = [1, 2, 3, 4]; % MCSs that are required for the standard
mcs = 2;
% [modorder, Ncbps, ldpc_cr, Mbps, cw_len,...
%     n_data_bits, Ncbpb, rep]  = mcsParams(2);

% setting up awgn channel
awgnChannel = comm.AWGNChannel('NoiseMethod','Variance','Variance',1);
errorRate = comm.ErrorRate;
berVec = zeros(n_frames, snr_len);


% for mcs = MCS_idx % run the simulation for each MCS index
    for frame_num = 1:n_frames % average results over n_frames
        for snr = 1:snr_len % for every snr value
        
            % init error statistics vector to calculate the BER
            errorStats = zeros(1,3);
            % get code rate, modulation order from MCS to scale noise poewr
            [modOrder, ~, codeRate, ~, ~, ~, ~, ~]  = mcsParams(mcs);
            % Calculating the noise variance and converting EbNo to SNR with
            % modificaitons to account for the error control coding
            EsNo = snr_vec(snr) + 10*log10(modOrder);       
            snrdB = EsNo + 10*log10(codeRate);      
            noiseVar = 1./(10.^(snrdB/10)); 
            % Adding the proper noise to the channel cooresponding to the SNR
            awgnChannel.Variance = noiseVar;

            while errorStats(3) < 1e7
                % generate random PSDU bits
                psdu_bits_tx = randi([0 1],n_octets*8,1);
                % generate random seed for scrambling sequences
                seed = randi([0 1],1,7);
                % generate frame
                [frame_tx] = txFrame.conFrame(psdu_bits_tx, n_octets, mcs, seed);
                % apply channel
                frame_rx = awgnChannel(frame_tx);
                % recover the PSDU bits from the received frame
                psdu_bits_rx = rxFrame.deconFrame(frame_rx, mcs, seed, n_octets);

                errorStats = errorRate(psdu_bits_tx,double(psdu_bits_rx));

            end % end while loop for errorRate calc
            % save the BER data for the specified SNR and reset the bit and
            % reset the bit error rate object
            berVec(frame_num,snr) = errorStats(1);
            reset(errorRate)
        end % end snr loop
    end % end n_frames loop
% end % end MCS loop