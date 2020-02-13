% defining functions associated with modulation
classdef modulator
    methods(Static)
        
        function [mod_data] = pskmod(data, phase, M)
            % psk modulator w/ a specified phase offset (typ. pi/2)
             pskModulator = comm.PSKModulator(M,phase,'BitInput',true);
             mod_data = pskModulator(data);
        end
        
        function [demod_data] = pskdemod(data, phase, M)
            % psk modulator w/ a specified phase offset (typ. pi/2)
             pskDemodulator = comm.PSKDemodulator(M, phase,'BitOutput',...
                 true,'DecisionMethod','Approximate log-likelihood ratio');
             demod_data = pskDemodulator(data);
        end


        
    end
end