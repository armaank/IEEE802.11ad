% Receiving a single frame following the IEEE 802.11ad standard
classdef rxFrame
    methods(Static)
        
        function [PSDU_rx] = deconFrame(rx_frame, n_octets, mcs, seed)
            % function to deconstruct received frame
            % inputs: rx_packet - the recieved frame 
            % outputs: 
            
            [STF_rx, CEF_rx, header_rx, data_rx] = ...
                rxFrame.parseFrame(rx_frame);
            % since equalization isn't part of the spec, we don't need to
            % do anything with the STF and CEF fields, we only need to
            % parse the data to check the BER

            [PSDU_rx] = ...
                rxFrame.deconData(data_rx, mcs, seed, n_octets);
           
            
        end % end deconFrame
        
        function [STF_rx, CEF_rx, ...
                header_rx, data_rx] = parseFrame(rx_frame)
            % function to parse the recieved frame 
            % inputs: rx_frame - the received frame
            % outputs: STF_rx - the rx STF 
            %          CEF_rx - the rx CEF
            %          header_rx - the rx header
            %          data_rx - the rx data
            %
            
            % parsing received frame - we can parse explicitly here because
            % lengths of STF, CEF and header are the same accross all MCS,
            % number of data bits, etc. 
            STF_rx = rx_frame(1:2176); 
            CEF_rx = rx_frame(2176+1:2176+1152); 
            header_rx = rx_frame(2176+1152+1:2176+1152+1024); 
            data_rx = rx_frame(2176+1152+1024+1:end);
            
        end % end parseFrame
                
        function [psdu_rx] = deconData(data_rx, mcs, seed, n_octets)
            % function to deconstruct data for BER computation
            % inputs: data_rx - parsed data field
            %         mcs - the modulation coding scheme, recovered from
            %               the header
            %         seed - the random seed used to init the scrambler,
            %                recovered from the header
            %         n_octets - the number of data octets, recovered from
            %                    the header
            % outputs: 
            
            % retrieving mcs-dependent constants
            [modorder, Ncbps, ldpc_cr, Mbps, cw_len, n_data_bits,...
                Ncbpb, reps ] = mcsParams(mcs);
            % computing padding sizes
            n_cw = ceil((n_octets*8)/((cw_len/reps)*ldpc_cr));   
            psdu_pad = (n_cw*(cw_len/reps)*ldpc_cr)-(n_octets*8);
            n_blks = ceil((n_cw*cw_len)/Ncbpb);
            %n_blks = n_blks
            n_blk_pad = (n_blks*Ncbpb)-(n_cw*cw_len);

            % perform GI removal
            Ga64_mod_rx = zeros(n_blks+1, 64); 
            % remove Ga64 at the end of rx data blocks stream
            data_rx_len = length(data_rx);
            Ga64_mod_rx(n_blks+1, :) = ...
                data_rx(1, data_rx_len-64+1:data_rx_len);
            data_rx(data_rx_len-64+1:data_rx_len) = [];
            data_mod_rx_GI = reshape(data_rx, 512, []).';
            n_fft = 512;
            % demodulate gaurd interval
            gaurd_rx = data_mod_rx_GI(:,1:64);
            %gaurd_rx_size = size(gaurd_rx)
            %gaurd_mod_rx_size = size(Ga64_mod_rx(1:n_blks, :))
            Ga64_mod_rx(1:n_blks, :) = gaurd_rx;
            k_Ga64 = 0:64-1;
            Ga64_rx = ...
                Ga64_mod_rx.*repmat(exp(-1j*pi*k_Ga64/2), n_blks+1, 1);
            % can probably remove
            data_mod_rx_blocks = data_mod_rx_GI(:,64+1:n_fft);
            
            % demodulate blocked data
            data_mod_rx = reshape(-data_mod_rx_blocks.', 1, []).';
            data_demod_rx = ...
                modulator.pskdemod(data_mod_rx, pi/2, modorder);
        
            % LDPC decoding data
            len_psdu_rx_padded = 8*n_octets + psdu_pad;
            rx_scram_seq = scram(len_psdu_rx_padded+n_blk_pad, seed);
            % scrambling seq for input data
            scram_seq_data_rx = rx_scram_seq(1:len_psdu_rx_padded); 
            % scrambling seq for block
            scram_seq_block_rx = rx_scram_seq(len_psdu_rx_padded+1:end);
            ldpc_in = data_demod_rx(1:length(data_demod_rx)-n_blk_pad,:);
            
            % generate partiy check matrix for LDPC code
            H_data = codes.pcm(ldpc_cr);
            % decoding algo
            switch(reps)
                case 1
                    % reshape input codeword to decode to N_cw rows
                    decode_in_cw = reshape(ldpc_in,[],n_cw).';
                    % scrambler output is broken into blocks of L_cwd bits
                    L_cwd = cw_len*ldpc_cr;

                    % preallocate output of the decoder
                    decoderOut_cw_tmp = zeros(n_cw, L_cwd); % all cw

                    % decode each code word
                    for ii = 1:n_cw
                        decoderIn_cw_temp = decode_in_cw(ii, :);

                        decoderOut_cw = ...
                            codes.ldpc_decode(-decoderIn_cw_temp.',H_data);
                        decoderOut_cw_tmp(ii, :) = decoderOut_cw.';
                    end % end for loop

                case 2
                    len_zeros = cw_len/(2*reps); % Length of block in bits
                    n_zeros = len_zeros; % number of zeros

                    % preallocate output of the decoder
                    decoderOut_cw_tmp = zeros(n_cw, len_zeros); % all cw


                    % reshape input codeword to decode to N_cw rows
                    decode_in_cw = reshape(ldpc_in,[],n_cw).';

                    for ii = 1:n_cw
                        decoderIn_cw_temp = decode_in_cw(ii, :);
                 
                        decoderIn_cw_rep_scram = decoderIn_cw_temp(1, len_zeros+1:len_zeros+n_zeros);
                        PNseq_for_repetition = scram(length(decoderIn_cw_rep_scram), [1 1 1 1 1 1 1]);
                        decoderIn_cw_rep = ((decoderIn_cw_rep_scram.').*(-2*PNseq_for_repetition+1)).';
                        % replace repeated part in decoderIn_cw_temp by zero symbols (log. 0 = +1)
                        decoderIn_cw_temp(1, len_zeros+1:len_zeros+n_zeros) = +10;
                        decoderIn_cw_temp(1,1:len_zeros) = decoderIn_cw_temp(1,1:len_zeros)+decoderIn_cw_rep;
                        decoderOut_cw = codes.ldpc_decode(-decoderIn_cw_temp.', H_data);
                        decoderOut_cw_tmp(ii, :) = decoderOut_cw(1:len_zeros).';
                    end

                    
            end % end switch
            
            ldpc_out = reshape(decoderOut_cw_tmp.',[],1).';
            
            % descramble output to recover transmitted bits
            data_descram = xor(ldpc_out.', scram_seq_data_rx);
            psdu_rx = data_descram(1:n_octets*8,1);
            
        end % end deconData
        
        
    end % end methods
end % end classdef