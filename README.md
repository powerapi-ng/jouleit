# jouleit
A repository of scripts that can be used to monitor energy consumption for any program.


# Requirements  
- *Linux*: 
Right now **jouleit** uses the Intel "_Running Average Power Limit_" (RAPL) technology that estimates power consumption of the CPU, ram and integrated GPU.
This technology is available on Intel CPU since the [Sandy Bridge generation](https://fr.wikipedia.org/wiki/Intel#Historique_des_microprocesseurs_produits)(2010).

- *gawk* 
You can install in debian distributions by running 
    
    apt install gawk

# How to use 

    ./jouleit.sh cmd 

**jouleit** offers a set of options to help benchmarking and testing programs. The avialable options are 

## Flags and options 

|**Flag**|**Description**|**Default value**|
|--------|---------------|:---------------:|
| -a | print the details of all sockets instead of the aggregation | False | 
| -b | print the results in the format of *KEY1;VALUE1;KEY2;VALUE2.. | False | 
| -l | list all the available domaines ( CPU, DRAM ..etc ) and print them in the form of a header of csv | |
| -c | Print only the values in csv format ( value1;value2;value3), We recommend using this after running the **jouleit** with -l Flag to see the order of the measured values | false | 
| -s **#N** | measure only the energy of the socket **#N** | all the available sockets |
| -o **filename** | redirect the output and the log of the executed program in the file `filename | current terminal |
| -n **N** | Run the programm **N** times and record the measured values in `data1234.csv` file |    | 




# Common issues

## function asort never defined

If running the `jouleit`-script throws an error, stating that the function
`asort` is not defined, try installing `gawk`.
 
 
 apt install gawk


