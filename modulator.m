% defining functions associated with modulation
classdef modulator
    methods(Static)
        
        function [mod_data] = bpskmod(data, phase)
            % bpsk modulator w/ a specified phase offset (typ. pi/2)
             bpskModulator = comm.BPSKMODULATOR;
             bpskModulator.PhaseOffset = phase;
             mod_data = bpskModulator(data);
        end

        
    end
end