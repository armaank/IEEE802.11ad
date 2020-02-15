% wls for directional multi-gigabit (DMG) single carrier (SC) PHY layer for
% IEEE802.11ad
%% Simulation Parameters
mcs = 2 % modulation and coding scheme index
n_octets = 5 % number of data octets in PSDU (find abbrev)
[modtype, Ncbps, ldpc_cr, Mbps, cw_size, n_data_bits, Ncbpb, reps ] ...
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

%% LDPC Encoding
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



                         









