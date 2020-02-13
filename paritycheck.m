% generates partiy check matrix for LDPC codes as defined in the
% IEEE802.11ad spec
classdef paritycheck
methods(Static)

function [PCM] = pcm(coderate)

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
           ]; % if this is wrong kill me
       
        PCM = paritycheck.makePCM(H, P, I);
        



    end
end
    
function [Ishift] = LDPC_shift(Pblock, I)
    if (isnan(Pblock))
        Ishift = zeros(size(I));
    else
        Ishift = circshift(I, [Pblock,2]);
    end
end

function [H] = makePCM(H, P, I)
    Z = size(I);
    for ii=1:size(P,1)
        for jj=1:size(P,2)
                    H((ii-1)*Z(1)+1:ii*Z(1),(jj-1)*Z(2)+1:jj*Z(2) ) = ...
                        paritycheck.LDPC_shift(P(ii,jj), I);
        end
    end
end
        
end
end