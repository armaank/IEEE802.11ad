% functions associated with modulation
classdef modulator
    methods(Static)
        
%         function [modOut] = mod(modIn, phase, M)
%             % modulator 
%             % inputs: modIn - input to modulator
%             %         phase - phase offset for constellation (typ. pi/2)
%             %         M - modulation order
%             if(M==2 || M==4 ||M==16 || M==8)
%                 modOut = modulator.pskmod(modIn, phase, M);
%             %elseif (M==4)
%                 %modOut = modulator.pskmod(modIn, phase, M);
%                 %rectqamMod = qammod('ModulationOrder',M,'BitInput',true);
%                 %modOut = rectqamMod(modIn);
% %                 modOut = modulator.qamMod(modIn, phase, M);
%             else
%                 warning("choose correction modulation order (2, 4, 16)")
%             end
%         end
%         function [demodOut] = demod(demodIn, phase, M)
%             % modulator
%             % inputs: demodIn - input to modulator
%             %         phase - phase offset for constellation (typ. pi/2)
%             %         M - modulation order
%             if(M==2 || M==16 || M==4 || M==8)
%                 demodOut = modulator.pskdemod(demodIn, phase, M);
% %             elseif (M==4)
% %                 %rectqamMod = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitInput',true);
% %                 %demodOut = rectqamMod(demodIn);
% %                 demodOut = modulator.qamDemod(demodIn, phase, M);
%              else
%                 warning("choose correction modulation order (2, 4, 16)")
%            end
%         end
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
        
        function [modOut] = qamMod(demodIn, phase, M)
            % qam modulator 
            % inputs: modIn - input to modulator
            %         phase - phase offset for constellation (typ. pi/2)
            %         M - modulation order 
            % outputs: modOut - modulated input
            modOut = qammod(demodIn, M, 'InputType', 'bit');
        end
        
        function [demodOut] = qamDemod(demodIn, phase, M)
            % qam demodulator 
            % inputs: demodIn - input to demodulator
            %         phase - phase offset for constellation (typ. pi/2)
            %         M - modulation order 
            % outputs: demodOut - demodulated input
            demodOut = qamdemod(demodIn, M, 'OutputType', 'bit');
        
        end
        
    end
end