#!/bin/bash

# the option -v
while getopts "v" o; do
    case "${o}" in
    v)
        verbose="True"
        ;;
    esac
done

shift $((OPTIND - 1))

# Read data

read_energy() {
    components=$(find /sys/devices/virtual/powercap/intel-rapl -name "energy_uj")

    data=""
    for component in ${components[@]}; do

        name=$(cat ${component%energy_uj}/name)
        energy=$(cat $component)
        data=$data$component,$name,$energy\;
    done
    data="${data%;}"
    echo $data
}

read_maxenergy() {
    components=$(find /sys/devices/virtual/powercap/intel-rapl -name "energy_uj")

    data=""
    for component in ${components[@]}; do

        name=$(cat ${component%energy_uj}/name)
        energy=$(cat ${component%energy_uj}/max_energy_range_uj)
        data=$data$component,$name,$energy\;
    done
    data="${data%;}"
    echo $data
}

# Calculate the energyies

calculate_energy() {
    begins=$1
    ends=$2
    maxenergies=$3
    echo | awk -v begins=$begins -v ends=$ends -v maxenergies=$maxenergies 'BEGIN \
    {
    split(ends,ends1,";");
    split(begins,begins1,";");
    split(maxenergies,maxenergies1,";");


    for (i in ends1 ){
        split(ends1[i],dataends,",")
        names[dataends[1]]  = dataends[2]
        energiesends[dataends[1]] =dataends[3]
    }    

     for (i in begins1 ){
        split(begins1[i],databegins,",")
        energiesbegins[databegins[1]] =databegins[3]
    }      

    for (i in maxenergies1 ){
        split(max1[i],datamax,",")
        energiesmax[datamax[1]] =datamax[3]
    }      


    for (i in names ){

        x = energiesends[i] - energiesbegins[i]
        if (x < 0 )
            {
                x=x+datamaxenergies[i]
            }
        printf i","names[i]","x";" 
        }

    }'

}

#Printing functions

print_time() {
    beginT=$1
    endT=$2
    duration=$((($endT - $beginT) / 1000))

    echo " ------------------------------------------- "
    echo "|             execution time  (us)          |"
    echo " ------------------------------------------- "
    printf "|             %-30d|\n" $duration
    echo " ------------------------------------------- "

}

print_header() {

    printf "| CPU    | %-10s | %-19s |\n" "Component" "energy (uJ)"
    echo " ------------------------------------------- "
}

print_details() {

    echo | awk -v data=$1 'BEGIN \
    {
        split(data,data1,";");
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=path1[2]
            split(cpu,cpu1,'//')
            cpu=cpu1[1]
            if (match(name, "package")) { name = "cpu" }
            name =toupper(name)
            printf "| CPU-%-3d| %-10s | %-19d |\n" ,cpu,name,value
        }
    }'
    echo " ------------------------------------------- "
}

print_global() {

    echo | awk -v data=$1 'BEGIN \
    {
        
        split(data,data1,";");
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=path1[2]
            split(cpu,cpu1,'//')
            cpu=cpu1[1]
            energies[name]=energies[name]+value
        }
        for (i in energies ) {
            # printf "global %s %d \n" ,toupper(i),energies[i] 
            printf "| Global | %-10s | %-19d |\n" , toupper(i),energies[i]
        }
    }'
    echo " ------------------------------------------- "

}

###############################
maxenergies=$(read_maxenergy)

begin_energy=$(read_energy)
beginT=$(date +"%s%N")

###############################################
$@
###############################################
endT=$(date +"%s%N")
end_energy=$(read_energy)

### Calculate the energies

energies=$(calculate_energy $begin_energy $end_energy $maxenergies)

# Remove the last ;
energies="${energies%;}"
# Change package with CPU
energies=$(echo $energies | sed -r 's/package-([0-9]+)/cpu/g')

## Visualisation
print_time $beginT $endT
print_header
print_global $energies

if [ -n "$verbose" ]; then
    print_details $energies
fi
