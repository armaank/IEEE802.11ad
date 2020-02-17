% Generating a single frame following the IEEE 802.11ad standard
classdef txFrame
    methods(Static)
        
        function [frame_tx] = conFrame(psdu_bits_tx, n_octets, mcs, seed);
            % constructs a final frame for tx 
            % inputs: psdu_bits_tx - input bitstream
            %         n_octets - number of octets in bitstream
            %         mcs - modulation and coding scheme index
            %         seed - random seed used to init scrambler
            % outputs: packet_tx - a single packet ready for tx
            
            % construct STF
            STF_tx = txFrame.conSTF();
            % construct CEF
            CEF_tx = txFrame.conCEF();
            % construct header
            header_tx = txFrame.conHeader(mcs, n_octets, seed);
            % construct data 
            data_tx = txFrame.conData(psdu_bits_tx, mcs, n_octets, seed);
            % put together final frame 
            frame_tx = [STF_tx, CEF_tx, header_tx, data_tx];
            
        end % end conFrame
        
        function [STF_tx] = conSTF()
            % constructing the short training field (STF)
            % outputs: modulated STF
            
            Ga128 = golay('a128');
            STF = [repmat(Ga128, 1, 16), -Ga128];
            % STF field is complete
            
            % pi/2 bpsk modulating STF
            k_stf = [0:length(STF)-1];
            STF_mod = STF.*exp(1j*pi*k_stf/2);
            
            STF_tx = STF_mod;
            
        end % end conSTF
        
        function [CEF_tx] = conCEF()
            % constructing the channel estimation field
            % outputs: modulated CEF
             
            Ga128 = golay('a128');
            Gb128 = golay('b128');
            Gu512 = [-Gb128, -Ga128, +Gb128, -Ga128];
            Gv512 = [-Gb128, +Ga128, -Gb128, -Ga128];
            Gv128 = -Gb128;
            CEF = [Gu512, Gv512, Gv128];
            % CEF field is complete
            
            % pi/2 bpsk modulating CEF
            k_cef = [0:length(CEF)-1];
            CEF_mod = CEF.*exp(1j*pi*k_cef/2);
            
            CEF_tx = CEF_mod;
            
        end % end CEF
        
        function [header_tx] = conHeader(mcs, n_octets, seed)
            % constructing the header for a single frame
            % inputs: mcs - modulation coding scheme (MCS) index
            %         n_octets - number of octets in data field
            %         rand_seed - 7 bit random seed used to init scrambler
            % outputs: header ready for tx (scrambled, mod, GIs and LDPC)
            
            % constructing header field
            header = nan(64,1);
            % LFSR seed stored in first 7 bits of the header
            header(1:7) = rand_eed; 
            % index for the MCS table, 24 total options so 5 bits
            mcsIdx = double(dec2bin(mcs, 5)-'0');
            % MCS index stored in header starting at the 7th bit
            header(8:12) = mcsIdx;
            % number of data octets (length) stored starting 
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
            % header field is complete 
            
            % scramble header (except the first seven bits)
            scram_seq_header = scram(length(header)-7 ,seed);
            scrambled_header = ...
                [header(1:7); xor(header(8:end), scram_seq_header)];
            
            % LDPC encoding header w/ rate = 3/4 
            H_header = codes.pcm(3/4); % generating parity check matrix 
            padded_scrambled_header = ...
                [scrambled_header; zeros(1, 504 - length(header)).'];
            encoded_header = ...
                codes.ldpc(padded_scrambled_header, H_header);
            % splitting up the header into code words
            cw1 = encoded_header; cw2 = encoded_header;
            cw1([length(header)+1:504, 665:672]) = []; 
            cw2([length(header)+1:504, 657:664]) = []; 
            scram_seq_cw2 = scramscramblerSeq(length(cw2), ones(7,1));
            cw2_scrambled = xor(cw2, scram_seq_cw2);
            header_cw = [cw1; cw2_scrambled];
            
            % pi/2 bpsk modulating the header
            header_mod = modulator.pskmod(header_cw, pi/2, 2);
            % gaurd insertion for the header
            Ga64 = golay('a64');
            % modulating the golay sequence
            k_ga = 0:63;
            Ga64_mod = Ga64.*exp(1j*pi*k_ga/2);
            
            header_tx = [Ga64_mod.';header_mod; Ga64_mod.';-header_mod].';            
            
        end % end conHeader
              
        function [data_tx] = conData(psdu_bits_tx, n_octets, mcs, seed)
            % constructs the data field for tx
            % inputs: psdu_bits - bits for tx
            %         n_octets - number of octets (bits/8)
            %         mcs - modulation and coding scheme index
            %         rand_seed - random seed used to init scrambler
            % outputs: 
            
            % retrieving mcs-dependent constants
            [modorder, Ncbps, ldpc_cr, Mbps, cw_len, n_data_bits,...
                Ncbpb, reps ] = mcsParams(mcs);
            % add code rate dependent padding
            n_cw = ceil((n_octets*8)/((cw_len/reps)*ldpc_cr));   
            psdu_pad = (n_cw*(cw_len/reps)*ldpc_cr)-(n_octets*8);
            psdu_tx_paded = [psdu_bits_tx; zeros(psdu_pad,1)];
            % compute number of blocks, padding
            n_blks = ceil((n_cw*cw_len)/Ncbpb);
            n_blk_pad = (n_blks*Ncbpb)-(n_cw*cw_len);

            % generate scrambling sequence from seed and data length
            scram_seq = scram(length(psdu_tx_paded) + n_blk_pad, seed);
            scram_seq_data = scram_seq(1:length(psdu_tx_paded));
            scram_seq_block = scram_seq(length(psdu_tx_paded)+1:end);
            % scramble data
            data_scrambled = xor(psdu_tx_paded, scram_seq_data);

            % LDPC encode data
            % generate partiy check matrix from code rate
            H_data = codes.pcm(ldpc_cr);
            % LDPC encoding depends on if repetition is used or not
            switch(reps)
                case 1
                    % preallocation of output auxiliary matrix
                    encOut = zeros(n_cw, cw_len);
                    % scrambler output is broken into blocks of L_cwd bits
                    L_cwd = cw_len*ldpc_cr;
                    % sequences of length L_cwd, each 
                    encInBlocks = reshape(data_scrambled, L_cwd, []).';
                    % encode each data word
                    for ii = 1:n_cw
                        encoderIn_cw_temp = encInBlocks(ii, :);

                        encOut_cw = codes.ldpc(encoderIn_cw_temp.', H_data);
                        encOut_cw = encOut_cw.';
                        encOut(ii, :) = encOut_cw;
                    end % end for loop for ldpc 
                otherwise
                    warning('choose a valid repetiton number (1 )')
            end % end switch

            ldpc_out = reshape(encOut.', 1, []);

            % add padding to output, apply scrambling sequence to pad
            block_pad = zeros(n_blk_pad, 1);
            block_pad_scrambled = xor(block_pad, scram_seq_block); 

            encoderOut = [ldpc_out, block_pad_scrambled.']; 
            % modulate data
            mod_data = modulator.pskmod(encoderOut.', pi/2, modorder);
            
            % adding GIs
            mod_data_blocks = reshape(mod_data, [], n_blks);
            Ga64 = golay('a64');
            % modulating the golay sequence
            k_ga = 0:63;
            Ga64_mod = Ga64.*exp(1j*pi*k_ga/2);
            GI = repmat(Ga64_mod, n_blks, 1);

            gaurded_mod_data = [GI, mod_data_blocks.'];
            % single stream of guard and blocks
            blocked_data = reshape(gaurded_mod_data.',[],1).';
            % add the last guard on the end of the final block
            blocked_data = [blocked_data, Ga64_mod];
    
            data_tx = blocked_data;
                       
        end % end conData
    
    end
end
