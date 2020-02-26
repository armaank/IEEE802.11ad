# IEEE802.11ad

PHY layer simulation of a directional, multi-gigabit wireless system

## Requirements 

All simulations are written in MATLAB2019b, and require the DSP and Comms Toolboxes. 

## Basic Usage
To simulate the standard over an AWGN channel, please see `wls.m` 

In that file, you can specify a modulation and coding scheme, the amount of data, the number of frames and the range of SNR values to compute bit error rates for. Note that the simulations take a significant amount of time. Lower MCSs indicies can take an extremely long time (>12 hours). Higher order MCSs take less time to simulate (~1-2 hours). In particular, MCS 1 takes an extremely long time to run due to the repetition used in the LDPC codes. After running simulations, or a set of simulations, save the `.mat` file containing the BER and use the `plot_ber.m` script in the `results` folder to generate waterfall curves.  

## Results

You can find my full report on IEEE802.11ad ![here](docs/report/kohli_ece408_standards.pdf). You can also see the waterfall curves and `.mat` files in the `results` directory. 


## Reference
[1] IEEE Standard for Information technology--Telecommunications and information exchange between systems--Local and metropolitan area networks--Specific requirements-Part 11: Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications Amendment 3: Enhancements for Very High Throughput in the 60 GHz Band," in IEEE Std 802.11ad-2012 (Amendment to IEEE Std 802.11-2012, as amended by IEEE Std 802.11ae-2012 and IEEE Std 802.11aa-2012) , vol., no., pp.1-628, 28 Dec. 2012


