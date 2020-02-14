% wls for directional multi-gigabit (DMG) single carrier (SC) PHY layer for
% IEEE802.11ad
%% Simulation Parameters
mcs = 1 % modulation and coding scheme index
length = 5 % number of data octets in PSDU (find abbrev)
%% Frame
% assembling the frame for tx

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
header(13:30) = double(dec2bin(length,18)-'0');
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
lastRSSI = [0 0 0 0]; % for power distribution
header(40:43) = lastRSSI;
turnaround = 0; % for ?
header(44) = turnaround;
reserved = [0 0 0 0]; % always set to zero
header(45:48) = reserved;
% header check sequence
HCS = codes.crc16(header(1:48));
header(49:end) = HCS;

% header complete 
                         









