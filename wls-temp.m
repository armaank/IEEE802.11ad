% wls for directional multi-gigabit (DMG) single carrier (SC) PHY layer for
% IEEE802.11ad
%% Simulation Parameters
mcs = 2 % modulation and coding scheme index
n_octets = 5 % number of data octets in PSDU (find abbrev)
[modorder, Ncbps, ldpc_cr, Mbps, cw_size, n_data_bits, Ncbpb, reps ] ...
    = mcsParams(mcs)
%% Frame 
% assembling the frame for tx

% constructing the short training field (STF)
% STF is comprised of golay sequences defined in the spec
Ga128 = golay('a128');
Gb128 = golay('b128');
STF = [repmat(Ga128, 1, 16), -Ga128];
% STF complete

% constructing the channel estimation field (CEF)
% CEF is also comprimised of golay sequences
Gu512 = [-Gb128, -Ga128, +Gb128, -Ga128];
Gv512 = [-Gb128, +Ga128, -Gb128, -Ga128];
Gv128 = -Gb128;
CEF = [Gu512, Gv512, Gv128];
%CEF complete

% constructing header field
header = nan(64,1);
 % 7-bit sequence to seed LFSR for the bit scrambler
randSeed = randi([0,1],1,7);
% LFSR seed stored in first 7 bits of the header
header(1:7) = randSeed; 
% index for the MCS table, 24 total options so 5 bits
mcsIdx = double(dec2bin(mcs, 5)-'0');
% MCS index stored in header starting at the 7th bit
header(8:12) = mcsIdx;
% number of data octets (length) stored starting at the 12th bit
header(13:30) = double(dec2bin(n_octets,18)-'0');
% "contains a copy of the parameter ADD_PPDU etc. page 470"
addPPDU = 0; % set to zero for now, can change later
header(31) = addPPDU ; % change later
packetType = 0; % control bit, set to zero
header(32) =  packetType; % can change later, not needed
trainingLength = [0 0 0 0 0]; % for beamforming
header(33:37) = trainingLength;
aggregation = 0; % for beamforming
header(38) = aggregation;
beamTrackingRequest = 0; % for beamforming
header(39) = beamTrackingRequest;
lastRSSI = [1 1 1 1]; % for power distribution
header(40:43) = lastRSSI;
turnaround = 0; % for ?
header(44) = turnaround;
reserved = [0 0 0 0]; % always set to zero
header(45:48) = reserved;
% header check sequence
HCS = codes.crc16(header(1:48));
header(49:end) = HCS;
% header complete 
%% Constructing Data  
% use random data for now
PSDU_tx = randi([0 1],n_octets*8,1);
% add code rate dependent padding
n_cw = ceil((n_octets*8)/((cw_size/reps)*ldpc_cr));   
PSDU_pad = (n_cw*(cw_size/reps)*ldpc_cr)-(n_octets*8);
PSDU_tx_paded = [PSDU_tx; zeros(PSDU_pad,1)];

N_blks = ceil((n_cw*cw_size)/Ncbpb);
N_blk_pad = (N_blks*Ncbpb)-(n_cw*cw_size)
        
%% Scrambling
% generate random seed 
seed = randi([0,1], 1, 7);
% generate scrambling sequence from seed and data length
scram_seq = dataGen.scramblerSeq(length(PSDU_tx_paded) + N_blk_pad, seed);
scram_seq_data = scram_seq(1:length(PSDU_tx_paded));
scram_seq_block_pad = scram_seq(length(PSDU_tx_paded)+1:end);
% scramble data
scramblerOut = xor(PSDU_tx_paded, scram_seq_data)

%% Data Coding
% generate partiy check matrix from code rate
pcm = codes.pcm(ldpc_cr);
% LDPC encoding depends on if repetition is used or not
switch(reps)
    case 1
        % preallocation of output auxiliary matrix
        encoderOut_all_cw = zeros(n_cw, cw_size);
        % scrambler output stream is broken into blocks of L_cwd bits
        L_cwd = cw_size*ldpc_cr;
        % sequences of length L_cwd, each row = single input data word
        encoderIn_data_blocks = reshape(scramblerOut, L_cwd, []).';
        % encode each data word
        for i_cw = 1:n_cw
            encoderIn_cw_temp = encoderIn_data_blocks(i_cw, :);

            encoderOut_cw_temp = codes.ldpc(encoderIn_cw_temp.', pcm);
            encoderOut_cw_temp = encoderOut_cw_temp.';
            % save input word and parity to matrix (each row = 1 codeword)
            encoderOut_all_cw(i_cw, :) = encoderOut_cw_temp;
        end
    otherwise
        warning('choose a valid repetiton number (1 )')
end
encoderOut_single_row = reshape(encoderOut_all_cw.', 1, []);

% d] divide to symbol blocks and add symbol pad bits
% e] concatenation of coded bit stream and N_blk_pad zeros
block_pad_zeros = zeros(N_blk_pad, 1);
% scrambling of block pad bits with continuous scrambling sequence from
% data scrambling
scrambled_block_pad_zeros = xor(block_pad_zeros, scram_seq_block_pad); % tx block pad zeros scrambling ON

% concatenation
encoderOut = [encoderOut_single_row, scrambled_block_pad_zeros.']; % for raw BER computing

%% Modulation
% modulating the data only right now, CEF, header and STF are modulated
% seperately w/ a different scheme

mod_data = modulator.pskmod(encoderOut.', pi/2, modorder);

%% Symbol Blocking and Gaurd Inverval Insertion 
mod_data_blocks = reshape(mod_data, [], N_blks);
Ga64 = golay('a64');
% modulating the golay sequence
k_ga = 0:63;
Ga64_mod = Ga64.*exp(1j*pi*k_ga/2);
GI = repmat(Ga64_mod, N_blks, 1);
                    
gaurded_mod_data = [GI, mod_data_blocks.'];
% single stream of guard and blocks
outputBlocks = reshape(gaurded_mod_data.',[],1).';
% add the last guard on the end of the final block
outputBlocks = [outputBlocks, Ga64_mod];

%% Modulating CEF and STF
% pi/2 bpsk modulating STF
k_stf = [0:length(STF)-1];
STF_mod = STF.*exp(1j*pi*k_stf/2);
% pi/2 bpsk modulating CEF
k_cef = [0:length(CEF)-1];
CEF_mod = CEF.*exp(1j*pi*k_cef/2);

%% Header Coding
% scramble header (except the first seven bits)
scram_seq_header = dataGen.scramblerSeq(length(header)-7 ,seed);
scrambled_header = [header(1:7); xor(header(8:end), scram_seq_header)]
% LDPC encoding header. rate = 3/4 for header, so need to generate new H
PCM_header = codes.pcm(3/4);
padded_scrambled_header = [scrambled_header; zeros(1, 504 - length(header)).']
encoded_header = codes.ldpc(padded_scrambled_header, PCM_header)
% setting up the two code words sequences from the spec
cws1 = encoded_header; cws2 = encoded_header;
cws1([length(header)+1:504, 665:672]) = []; 
cws2([length(header)+1:504, 657:664]) = []; 
scram_seq_cws2 = dataGen.scramblerSeq(length(cws2), ones(7,1));
cws2_scrambled = xor(cws2, scram_seq_cws2);
header_cw = [cws1;cws2_scrambled];

%% Header Modulation and Gaurd Insertion
% modulation
header_mod = modulator.pskmod(header_cw, pi/2, 2)
% gaurd insertion
gaurded_header = [Ga64_mod.'; header_mod; Ga64_mod'; -header_mod];
% careful with tranpose !!!!!!!!!!!
%% Constructing final packet for TX

packet = [STF_mod, CEF_mod, gaurded_header.', outputBlocks];


%% Rx

% after passing packet through awgn channel, we need to receive the packet,
% and decode it accordingly
% parsing received frame
rx_stf = packet(1:2176); % length of STF isn't dependent on MCS 
rx_cef = packet(2176+1:2176+1152); % length of CEF isn't dependent on MCS
rx_header = packet(2176+1152+1:2176+1152+1024); 
rx_data = packet(2176+1152+1024+1:end);

% Parse STF for timing synchronization (out of project spec)

% Perform channel equilization and estimation with CEF 
% since no equalizer is specified in the IEEE 802.11ad spec, we perform no
% channel equalization, so no need to perform any channel estimation

% Gaurd removal
rx_Ga64_mod = zeros(N_blks+1, 64); % preallocation (N_blks +1 of Ga64 sequences within data frame)
% remove Ga64 at the end of rx data blocks stream
rx_data_length = length(rx_data);
rx_Ga64_mod(N_blks+1, :) = rx_data(1, rx_data_length-64+1:rx_data_length);
rx_data(rx_data_length-64+1:rx_data_length) = [];
n_fft = 512
rx_modulatedDataSymbolsAndGuard = reshape(rx_data, n_fft, []).';
% rest of guard removal

rx_guard = rx_modulatedDataSymbolsAndGuard(:,1:64);
rx_Ga64_mod(1:N_blks, :) = rx_guard;
k_Ga64 = 0:64-1;
rx_Ga64 = rx_Ga64_mod.*repmat(exp(-1j*pi*k_Ga64/2), N_blks+1, 1);

rx_modulatedDataSymbol_blocks = rx_modulatedDataSymbolsAndGuard(:,64+1:n_fft);

rx_modulatedDataSymbol_blocks - mod_data_blocks.'

% Demodulation
% todo: extract info from header, demod header
rx_modulatedDataSymbol = reshape(-rx_modulatedDataSymbol_blocks.', 1, []).'
rx_demod_data = modulator.pskdemod(rx_modulatedDataSymbol, pi/2, modorder);
% redo, something strange w/ demod
% for ii=(1:length(rx_demod_data))
%    
%     if(rx_demod_data(ii) == -4)
%         rx_demod_data(ii)= 0;
%     else
%         rx_demod_data(ii) = 1;
%     end
% end
rx_demod_data.' - encoderOut
%rx_modulatedDataSymbol_blocks_derotated = rx_modulatedDataSymbol_blocks.*repmat(modulated_symbol_derotating_factor, N_blks, 1)

%% LDPC Decoding
% start with random seed to unscramble data (should do this after decoding
% header but ok for now)
len_PSDU_rx_padded = 8*n_octets + PSDU_pad;
rx_scram_seq = dataGen.scramblerSeq(len_PSDU_rx_padded+N_blk_pad, seed);

rx_scramblingSeq_data = rx_scram_seq(1:len_PSDU_rx_padded); % scrambling seq for input data
rx_scramblingSeq_block_pad = rx_scram_seq(len_PSDU_rx_padded+1:end); % scram

% encoderOut_single_row - decoderIn_extracted.'

decoderIn_extracted = rx_demod_data(1:length(rx_demod_data)-N_blk_pad,:);
% extract block pad zeros

encoderOut_single_row - decoderIn_extracted.'


extracted_blk_pads = rx_demod_data(end-N_blk_pad+1:end,:);
descrambled_blk_pads = extracted_blk_pads.*(-2*rx_scramblingSeq_block_pad+1); % should be all logical zeros (i.e. > 0)



PCM = codes.pcm(ldpc_cr);

switch(reps)
    case 1
        % reshape input codeword to decode to N_cw rows
        decoderIn_all_cw = reshape(decoderIn_extracted,[],n_cw).';
        % scrambler output stream is broken into blocks of L_cwd bits
        L_cwd = cw_size*ldpc_cr;

        % preallocate output of the decoder
        decoderOut_cw_tmp = zeros(n_cw, L_cwd); % all cw

        % decode each code word
        for i_cw = 1:n_cw
            decoderIn_cw_temp = decoderIn_all_cw(i_cw, :);
        
            decoderOut_cw = codes.ldpc_decode(-decoderIn_cw_temp.', PCM)
            decoderOut_cw_tmp(i_cw, :) = decoderOut_cw.';
        end
       
    case 2
       
        
end
decoderOut = reshape(decoderOut_cw_tmp.',[],1).';
decoderOut - scramblerOut'

%% TEST LDPC
% clc;
% clear;
% % PCM = codes.pcm(1/2)
% % data = randi([0 1],672/2,1);
% % ldpc_enc_data = codes.ldpc(data, PCM)
% % ldpc_enc_data = awgn(ldpc_enc_data,10);
% % ldpc_dec_data = codes.ldpc_decode(ldpc_enc_data, PCM)
% % ldpc_dec_data - data
% PCM = codes.pcm(1/2)
% M = 2; % Modulation order (QPSK)
% snr = 1;
% numFrames = 1;
% ldpcEncoder = comm.LDPCEncoder(PCM);
% ldpcDecoder = comm.LDPCDecoder(PCM);
% pskMod = comm.PSKModulator(M,'BitInput',true);
% pskDemod = comm.PSKDemodulator(M,'BitOutput',true,...
%     'DecisionMethod','Approximate log-likelihood ratio');
% pskuDemod = comm.PSKDemodulator(M,'BitOutput',true,...
%     'DecisionMethod','Hard decision');
% errRate = zeros(1,length(snr));
% uncErrRate = zeros(1,length(snr));
% for ii = 1:length(snr)
%     ttlErr = 0;
%     ttlErrUnc = 0;
%     pskDemod.Variance = 1/10^(snr(ii)/10); % Set variance using current SNR
%     for counter = 1:numFrames
%         data = (randi([0 1],672/2,1));
%         % Transmit and receiver uncoded signal data
%         mod_uncSig = pskMod(data);
%         rx_uncSig = awgn(mod_uncSig,snr(ii),'measured');
%         demod_uncSig = pskuDemod(rx_uncSig);
%         numErrUnc = biterr(data,demod_uncSig);
%         ttlErrUnc = ttlErrUnc + numErrUnc;
%         % Transmit and receive LDPC coded signal data
%         encData = ldpcEncoder(data);
%         modSig = pskMod(encData);
%         %rxSig = awgn(modSig,snr(ii),'measured');
%         demodSig = pskDemod(modSig);
%                 modSig - demodSig
% 
%         rxBits = ldpcDecoder(demodSig);
%         numErr = biterr(data,rxBits)
%         ttlErr = ttlErr + numErr;
%     end
%     ttlBits = numFrames*length(rxBits);
%     uncErrRate(ii) = ttlErrUnc/ttlBits;
%     errRate(ii) = ttlErr/ttlBits;
% end
%%
decoderIn_all_cw - encoderOut_all_cw
test_out = codes.ldpc_decode(decoderIn_all_cw.', PCM)

test_out - scramblerOut

decoderOut_cw = encoderOut_cw_temp;


decoderOut = reshape(decoderOut_cw_tmp.',[],1).';

decoderOut - scramblerOut.'

%% descarmble
descrambleOut = xor(decoderOut.', rx_scramblingSeq_data)
PSDU_rx = descrambleOut(1:n_octets*8,1)
PSDU_rx - PSDU_tx




