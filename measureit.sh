#!/bin/bash

######### generic functions
read_energy() {
    dir=$@
    energy=""
    for i in ${dir[@]}; do
        s=$(cat $i/energy_uj)
        energy=$energy$s","
    done
    echo $energy
}

read_maxenergy() {
    dir=$@
    energy=""
    for i in ${dir[@]}; do
        s=$(cat $i/max_energy_range_uj)
        energy=$energy$s","
    done
    echo $energy
}

calculate_energy() {
    begins=$1
    ends=$2
    maxenergies=$3
    echo | awk -v ends=$ends -v begins=$begins -v maxenergies=$MAXPKG 'BEGIN \
{   energiy=0;\
    split(ends,ends1,","); \
    split(begins,begins1,","); \
    split(maxenergies,maxenergies1,","); \
    for (i in ends1 ) {x= ends1[i] - begins1[i] ;\
        if (x < 0) {x=x+maxenergies1[i] } ;\
        energy += x ; \
    }\
    printf energy "\n"; \
} \
'
}

############### get the paths of each device #######################

x=$(find /sys/devices/virtual/powercap/intel-rapl -name "name")
drams=""
cores=""
for i in ${x[@]}; do
    s=$(cat $i)
    case $s in
    dram)
        drams+=${i%name}" "
        ;;
    core)
        cores+=${i%name}" "
        ;;
    esac
done

pkgs=$(find /sys/devices/virtual/powercap/intel-rapl/ -name intel-rapl\:[[:digit:]])

############# get the max energy window for each device #################
MAXPKG=$(read_maxenergy $pkgs)

if [ -n "$drams" ]; then
    MAXDRAM=$(read_maxenergy $drams)
fi

if [ -n "$cores" ]; then
    MAXCORES=$(read_maxenergy $cores)
fi

############# get the  energy  before the begining of the command for each device #################

beginpkg=$(read_energy $pkgs)

if [ -n "$drams" ]; then
    begindram=$(read_energy $drams)
fi

if [ -n "$cores" ]; then
    begincore=$(read_energy $cores)
fi
beginT=$(date +"%s%N")
########################## the command
$@

############# get the  energy  before the machine after the end  of the command for each device #################
endT=$(date +"%s%N")

endpkg=$(read_energy $pkgs)

if [ -n "$drams" ]; then
    enddram=$(read_energy $drams)
fi

if [ -n "$cores" ]; then
    endcore=$(read_energy $cores)
fi

## calculate the differences

duration=$((($endT - $beginT) / 1000000))

enegypkg=$(calculate_energy $beginpkg $endpkg $MAXPKG)

if [ -n "$drams" ]; then

    energydram=$(calculate_energy $begindram $enddram $MAXDRAM)

fi

if [ -n "$cores" ]; then
    energycore=$(calculate_energy $begincore $endcore $MAXCORE)

fi

#### printing the results
printf "execution time  : %10d ms\n" $duration

printf 'energy cpu      : %10d uj\n' $enegypkg

if [ -n "$drams" ]; then

    printf 'energy dram     : %10d uj\n' $energydram

fi

if [ -n "$cores" ]; then

    printf 'energy core-cpu : %10d uj\n' $energycore

fi
