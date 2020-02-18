% Function to retrieve all paramaters associated with each modulation
% coding scheme (MCS)
function [modorder, Ncbps, ldpc_cr, Mbps, cw_len,...
    n_data_bits, Ncbpb, rep]  = mcsParams(mcs_num)

switch(mcs_num)
    case 1
        modorder = 2; % pi/2 bpsk modulaton
        Ncbps = 1; % number of coded bits per symbol
        ldpc_cr = 1/2; % code rate 
        Mbps = 385; % data rate, mega bits per second
        cw_len = 672; % codeword size for 1/2 code rate
        n_data_bits = 336; % number of data bits for 1/2 code rate
        Ncbpb = 448; % number of coded bits per block
        rep = 2; % repitition for code rate ? 
    case 2
        modorder = 2; % pi/2 bpsk modulaton
        Ncbps = 1; % number of coded bits per symbol
        ldpc_cr = 1/2; % code rate 
        Mbps = 770; % data rate, mega bits per second
        cw_len = 672; % codeword size for 1/2 code rate
        n_data_bits = 336; % number of data bits for 1/2 code rate
        Ncbpb = 448; % number of coded bits per block
        rep = 1; % repitition for code rate ? 
    case 3
        modorder = 2; % pi/2 bpsk modulaton
        Ncbps = 1; % number of coded bits per symbol
        ldpc_cr = 5/8; % code rate 
        Mbps = 962.5; % data rate, mega bits per second
        cw_len = 672; % codeword size for 1/2 code rate
        n_data_bits = 420; % number of data bits for 1/2 code rate
        Ncbpb = 448; % number of coded bits per block
        rep = 1; % repitition for code rate ? 
    case 4
        modorder = 2; % pi/2 bpsk modulaton
        Ncbps = 1; % number of coded bits per symbol
        ldpc_cr = 3/4; % code rate 
        Mbps = 1155; % data rate, mega bits per second
        cw_len = 672; % codeword size for 1/2 code rate
        n_data_bits = 504; % number of data bits for 1/2 code rate
        Ncbpb = 448; % number of coded bits per block
        rep = 1; % repitition for code rate ? 
    otherwise
        warning('choose a valid mcs')
    
end