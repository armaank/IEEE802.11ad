% defining functions associated with data manipulation
classdef dataGen
    methods(Static)
        
        function [bits] = txt2msg(msg)
            % convert input msg to bits
            
        end
        
        function [msg] = bits2msg(bits)
            % convert bits back into human-readable message
            
        end
        
        function [seq, seed] = scramblerSeq(seqlen)
            % data scrambler
            % generates scrambling sequence from x^7 + x^4 + 1
            % input: seqlen - desired sequence length
            % output: seq - scrambling sequence 
            %         seed - random seed used to generate the sequence
            seed = randi([0,1],1,7); % 7-bit sequence to seed LFSR
            seq = nan(seqlen, 1);
            lfsr = seed;
            for ii = 1:seqlen
                seq(ii) = xor(lfsr(1), lfsr(4));
                lfsr = circshift(lfsr, [0,-1]);
                lfsr(7) = seq(ii);
            end            
        end
        
        function [seq_guard] = guard(seq)
            % add gaurd interval to bit sequence. gaurd interval consists 
            % of a pi/2 BPSK golay sequence
        
        end
        
        function [bits_inter] = interleaver(bits)
            % bit interleaver
        end
        
    end
end