% defining functions associated with data manipulation
classdef datagen
    methods(Static)
        
        function [msg] = txt2bits(text)
            % convert input text to bits
            
        end
        
        function [msg_scram] = srambler(msg)
            % scramble data w/ generator polynomial x^7 + x^4 + 1
            
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