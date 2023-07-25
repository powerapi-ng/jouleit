# jouleit
A repository of scripts that can be used to monitor energy consumption for any program.


# Requirements  
- *Linux*: 
Right now **jouleit** uses the Intel "_Running Average Power Limit_" (RAPL) technology that estimates power consumption of the CPU, ram and integrated GPU.
This technology is available on Intel CPU since the [Sandy Bridge generation](https://fr.wikipedia.org/wiki/Intel#Historique_des_microprocesseurs_produits)(2010).


# How to use 

   sudo ./jouleit.sh cmd 

**jouleit** offers a set of options to help benchmarking and testing programs. The avialable options are 

## Flags and options 

| **Flag**            | **Description**                                                                                                                                                        |     **Default value**     |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-----------------------: |
| -g                  | print the details of all sockets instead of the aggregation                                                                                                            |           False           |
| -b                  | print the results in the format of *KEY1:VALUE1;KEY2:VALUE2..                                                                                                          |           False           |
| -l                  | list all the available domains (CPU, DRAM, etc.) and print them in the form of a header of CSV                                                                         |                           |
| -c                  | print only the values in CSV format (value1;value2;value3). We recommend using this after running **jouleit** with the -l flag to see the order of the measured values |           false           |
| -s **s0**,**s1**,.. | measure only the energy of the component in the sockets **s1,s2...**                                                                                                   | all the available sockets |
| -o **filename**     | redirect the output and the log of the executed program to the file `filename`                                                                                         |     current terminal      |
| -n **N**            | run the program **N** times and record the measured values in `data1234.csv` file                                                                                      |                           |
| -h                  | display the help message                                                                                                                                               |                           |


# Examples

we want to measure a Python script called `work.py` 

instead of running it like this 

    python work.py 
![alone](https://github.com/powerapi-ng/jouleit/blob/master/img/example_alone.png)


we run it with **jouleit** like this 
   
      sudo ./jouleit.sh python work.py 

![the default option ](https://github.com/powerapi-ng/jouleit/blob/master/img/example_default.png)
if we want to aggregate the results we can use the flag `-g` 

    sudo ./jouleit.sh -g python work.py 
![aggregated version](https://github.com/powerapi-ng/jouleit/blob/master/img/example_aggregated.png)
