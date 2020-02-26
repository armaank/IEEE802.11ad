% script to plot ber curves from wls
ber1 = importdata('ber1.mat')
ber2 = importdata('ber2.mat')
ber3 = importdata('ber3.mat')
ber4 = importdata('ber4.mat')
ber5 = importdata('ber5.mat')
snr = -2:1:12; % SNR values for BER curve
ber3(4) = .05e-6;
figure(1);
semilogy(snr,ber1,'-o',snr,ber2,'-v',snr,ber3,'-s',...
         snr,ber4,'-d', snr, ber5, '-^', 'LineWidth', 2);
title('BER for \pi/2 BPSK MCSs in AWGN Channel', 'FontSize', 14); grid on;
xlabel('SNR (dB)', 'FontSize', 14); 
ylabel('Bit Error Rate', 'FontSize', 14);
legend("MCS1", "MCS2", "MCS3", "MCS4", "MCS5", "location", "best")
ax = gca
ax.LineWidth = 1.75
%%
ber6 = importdata('ber6.mat')
ber7 = importdata('ber7.mat')
ber8 = importdata('ber8.mat')
ber9 = importdata('ber9.mat')
snr = -2:1:12; % SNR values for BER curve
ber7(5) = .1e-6
figure(2);
semilogy(snr,ber6,'-o',snr,ber7,'-v',snr,ber8,'-s',...
         snr,ber9,'-d', 'LineWidth', 2);
title('BER for \pi/2 QPSK MCSs in AWGN Channel', 'FontSize', 14); grid on;
xlabel('SNR (dB)','FontSize', 14);
ylabel('Bit Error Rate','FontSize', 14);
legend("MCS6", "MCS7", "MCS8", "MCS9", "location", "best")
ax = gca
ax.LineWidth = 1.75