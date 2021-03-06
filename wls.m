%% Wireless link simulation for IEEE802.11 ad
clc;
clear;

%% Simulation Params

snr_vec = -2:1:12; % SNR values for BER curve
snr_len = length(snr_vec);
n_frames = 10; % number of iterations for the monte-carlo simulation
n_octets = 1000; % number of data octets in PSDU 

% MCSs that are required for the standard [1, 2, 3, 4]
% Simulations for lower MCS indicies span multiple hours, even days. 
% Higher MCS values have more bit errors, and take less time to simulate.
mcs = 9;   

%% Simulation
% setting up awgn channel
awgnChannel = comm.AWGNChannel('NoiseMethod','Variance','Variance',1);
errorRate = comm.ErrorRate;
berVec = zeros(n_frames, snr_len);


for frame_num = 1:n_frames % average results over n_frames
    for snr = 1:snr_len % for every snr value

        % init error statistics vector to calculate the BER
        errorStats = zeros(1,3);
        % get code rate, modulation order from MCS to scale noise power
        [modOrder, ~, codeRate, ~, ~, ~, ~, ~]  = mcsParams(mcs);
        % calculating the noise variance and converting EbNo to SNR with
        % modificaitons to account for the error control coding
        EsNo = snr_vec(snr) + 10*log10(modOrder);       
        snrdB = EsNo + 10*log10(codeRate);      
        noiseVar = 1./(10.^(snrdB/10)); 
        % adding the proper noise to the channel cooresponding to the SNR
        awgnChannel.Variance = noiseVar;

        while errorStats(3) < 5e6
            % generate random PSDU bits
            psdu_bits_tx = randi([0 1],n_octets*8,1);
            % generate random seed for scrambling sequences
            seed = randi([0 1],1,7);
            % generate frame
            [frame_tx] = txFrame.conFrame(psdu_bits_tx, n_octets, mcs, seed);
            % apply channel
            frame_rx = awgnChannel(frame_tx);
            % recover the PSDU bits from the received frame
            psdu_bits_rx = rxFrame.deconFrame(frame_rx, n_octets, mcs, seed);

            errorStats = errorRate(psdu_bits_tx,double(psdu_bits_rx));

        end % end while loop for errorRate calc
        % save the BER data for the specified SNR and reset the bit and
        % reset the bit error rate object
        berVec(frame_num,snr) = errorStats(1);
        reset(errorRate)
        
        disp_out_snr = sprintf(...
            'Done w/ BER computation for snr of %d, frame number %d', ...
            snr_vec(snr), frame_num);
        
        disp(disp_out_snr)
    end % end snr loop 
    disp_out_frame = sprintf('Done processing frame %d',frame_num);
    disp(disp_out_frame)
end % end n_frames loop

ber_Vec=mean(berVec,1);
figure(1)

%% Waterfall Plot Generation
% generating Waterfall Plot
semilogy(snr_vec,ber_Vec,'-*')
grid on
xlabel('SNR (dB)')
ylabel('Bit Error Rate')
title("BER Waterfall Curve");



