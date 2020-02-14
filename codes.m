% defining functions associated with error control coding
classdef codes
    methods(Static)

        function [ldpcSeq] = ldpc(seq, pcm)
            % ldpc encoder from MATLAB comms toolbox
            % inputs: seq - sequence to encode
            %         pcm - parity check matrix used to generate LDPC code
            % outputs: ldpcSeq - an LDPC encoded sequence
            ldpcEncoder = comm.LDPCEncoder(pcm);
            ldpcSeq = ldpcEncoder(seq);
        end

        function [seq] = ldpc_decode(ldpcSeq,pcm)
             % ldpc decoder from MATLAB comms toolbox
             % inputs: ldpcSeq - an LDPC encoded sequence
             %         pcm - parity check matrix used to generate LDPC code
             % outputs: seq - an LDPC deencoded sequence
            ldpcDecoder = comm.LDPCDecoder(pcm);
            seq = ldpcDecoder(ldpcSeq);
        end

        function [PCM] = pcm(coderate)
            % generate parity check matrix for LDPC code
            % inputs: coderate - coderate
            % outputs: PCM - partiy check matrix
            if(coderate == 1/2)
                H = sparse(336, 672); % size of parity check matrix
                Z = 42; % size of cyclic permutation matrix
                I = speye(Z);
                P =[40,nan, 38,nan, 13,nan,  5,nan, 18,nan,nan,nan,nan,nan,nan,nan;
                34,nan, 35,nan, 27,nan,nan, 30,  2,  1,nan,nan,nan,nan,nan,nan;
                nan, 36,nan, 31,nan,  7,nan, 34,nan, 10, 41,nan,nan,nan,nan,nan;
                nan, 27,nan, 18,nan, 12, 20,nan,nan,nan, 15,  6,nan,nan,nan,nan;
                35,nan, 41,nan, 40,nan, 39,nan, 28,nan,nan,  3, 28,nan,nan,nan;
                29,nan,  0,nan,nan, 22,nan,  4,nan, 28,nan, 27,nan, 23,nan,nan; 
                nan, 31,nan, 23,nan, 21,nan, 20,nan,nan, 12,nan,nan,  0, 13,nan;
                nan, 22,nan, 34, 31,nan, 14,nan,  4,nan,nan,nan, 13,nan, 22, 24;
                ]; 
            end
            PCM = codes.makePCM(H, P, I);               
        end

        function [Ishift] = LDPCshift(Pblock, I)
            % circ shifting logic for parity check matrix 
            % inputs: Pblock - pattern from 'generating' matrix for LDPC
            %         I - Identity matrix of correct size
            % outputs: Ishift - circshifted identity matrix according to
            %                   pattern matrix
            if (isnan(Pblock))
                Ishift = zeros(size(I));
            else
                Ishift = circshift(I, [Pblock,2]);
            end
        end

        function [H] = makePCM(H, P, I)
            % for loop for parity check matrix generation
            % inputs: H - sparse parity check matrix to be filled
            %         P - pattern matrix - find bettter name
            %         I - identity matrix of correct size
            % outputs: H - filled parity check matrix
            Z = size(I);
            for ii=1:size(P,1)
                for jj=1:size(P,2)
                      H((ii-1)*Z(1)+1:ii*Z(1),(jj-1)*Z(2)+1:jj*Z(2))...
                            = codes.LDPC_shift(P(ii,jj), I);
                end
            end
        end

    end % end methods
end % end classdef