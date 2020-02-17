function [seq] = scram(seqlen, seed)
    % data scrambler
    % generates scrambling sequence from x^7 + x^4 + 1
    % input: seqlen - desired sequence length
    %        seed - random seed used to generate the sequence
    % output: seq - scrambling sequence 
    seq = nan(seqlen, 1);
    lfsr = seed;
    for ii = 1:seqlen
        seq(ii) = xor(lfsr(1), lfsr(4));
        lfsr = circshift(lfsr, [0,-1]);
        lfsr(7) = seq(ii);
    end            
end
