% functions associated with modulation
classdef modulator
    methods(Static)
        

        function [modOut] = pskmod(modIn, phase, M)
            % psk modulator 
            % inputs: modIn - input to modulator
            %         phase - phase offset for constellation (typ. pi/2)
            %         M - modulation order (2 for bpsk, 4 for qpsk, etc.)
            % outputs: modOut - modulated input
             pskModulator = comm.PSKModulator(M,phase,'BitInput',true);
             modOut = pskModulator(modIn);
        end
        
        function [demodOut] = pskdemod(demodIn, phase, M)
            % psk demodulator 
            % inputs: demodIn - input to demodulator
            %         phase - phase offset for constellation (typ. pi/2)
            %         M - modulation order (2 for bpsk, 4 for qpsk, etc.)
            % outputs: demodOut - demodulated input
            pskDemodulator = comm.PSKDemodulator(M, phase,'BitOutput',...
                 true,'DecisionMethod','Approximate log-likelihood ratio');
             demodOut = pskDemodulator(demodIn);
        end
        
    end
end