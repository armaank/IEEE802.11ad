% Function to retrieve all paramaters associated with each modulation
% coding scheme (MCS)
function [mcs_params] = mcsParams(mcs_num)

switch(mcs_num)
    case 1
        modtype = 2; % pi/2 bpsk modulaton
        Ncbps = 1; % number of coded bits per symbol
        ldpc_cr = 1/2; % code rate 
        Mbps = 385; % data rate, mega bits per second
        cw_size = 672; % codeword size for 1/2 code rate
        n_data_bits = 336; % number of data bits for 1/2 code rate
        Ncbpb = 448; % number of coded bits per block
        % repetition =1 ?
        mcs_params = [modtype, Ncbps, ldpc_cr, Mbps, cw_size,...
            n_data_bits, Ncbpb];
    
    otherwise
        warning('choose a valid mcs')
    
end