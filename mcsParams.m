% Function to retrieve all paramaters associated with each modulation
% coding scheme (MCS)
function [modorder, Ncbps, ldpc_cr, Mbps, cw_len,...
    n_data_bits, Ncbpb, rep]  = mcsParams(mcs_num)

switch(mcs_num)
    
    case 1
        modorder = 2; % modulation order
        Ncbps = 1; % number of coded bits per symbol
        ldpc_cr = 1/2; % code rate 
        Mbps = 385; % data rate, mega bits per second
        cw_len = 672; % codeword size
        n_data_bits = 336; % number of data bits for code rate
        Ncbpb = 448; % number of coded bits per block
        rep = 2; % repetition for code rate  
        
    case 2
        modorder = 2; 
        Ncbps = 1; 
        ldpc_cr = 1/2; 
        Mbps = 770; 
        cw_len = 672; 
        n_data_bits = 336; 
        Ncbpb = 448; 
        rep = 1; 
        
    case 3
        modorder = 2; 
        Ncbps = 1; 
        ldpc_cr = 5/8;
        Mbps = 962.5; 
        cw_len = 672; 
        n_data_bits = 420; 
        Ncbpb = 448;
        rep = 1; 
        
    case 4
        modorder = 2; 
        Ncbps = 1; 
        ldpc_cr = 3/4; 
        Mbps = 1155; 
        cw_len = 672;
        n_data_bits = 504;
        Ncbpb = 448; 
        rep = 1;
        
    case 5
        modorder = 2; 
        Ncbps = 1; 
        ldpc_cr = 13/16; 
        Mbps = 1251.25; 
        cw_len = 672; 
        n_data_bits = 546; 
        Ncbpb = 448; 
        rep = 1; 
        
    case 6
        modorder = 4; 
        Ncbps = 2; 
        ldpc_cr = 1/2;
        Mbps = 1540; 
        cw_len = 672; 
        n_data_bits = 336; 
        Ncbpb = 896; 
        rep = 1; 
        
    case 7
        modorder = 4; 
        Ncbps = 2; 
        ldpc_cr = 5/8; 
        Mbps = 1925; 
        cw_len = 672;  
        n_data_bits = 420;
        Ncbpb = 896;
        rep = 1; 
        
    case 8
        modorder = 4; 
        Ncbps = 2; 
        ldpc_cr = 3/4; 
        Mbps = 2310; 
        cw_len = 672; 
        n_data_bits = 504; 
        Ncbpb = 896;
        rep = 1; 
        
    case 9
        modorder = 4; 
        Ncbps = 2; 
        ldpc_cr = 13/16; 
        Mbps = 2502.5; 
        cw_len = 672;
        n_data_bits = 546; 
        Ncbpb = 896; 
        rep = 1; 

    otherwise
        warning('choose a valid mcs')
    
end