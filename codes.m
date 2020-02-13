% defining functions associated with error control coding
classdef codes
   methods(Static)
       
       function [seq_ldpc] = ldpc(seq, pcm)
           %ldpc encodes a bit sequence
           ldpcEncoder = comm.LDPCEncoder(pcm);
           seq_ldpc = ldpcEncoder(seq)
       end
       
       function [ldpc_out] = ldpc_decode(seq,pcm)
           % decodes an ldpc
           ldpcDecoder = comm.LDPCDecoder(pcm);
           ldpc_out = ldpcDecoder(seq)
       end
       
       function [seq_golay] = golay(seq)
           % generates a golay sequence for the gaurd interval
       end
       
   end
    
end