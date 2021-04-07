#!/bin/bash

while getopts "v" o; do
    case "${o}" in
    v)
        verbose="True"
        ;;
    esac
done
shift $((OPTIND - 1))

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

calculate_energy_verbose() {
    begins=$1
    ends=$2
    maxenergies=$3
    echo | awk -v ends=$ends -v begins=$begins -v maxenergies=$MAXPKG 'BEGIN \
{   \
    split(ends,ends1,","); \
    split(begins,begins1,","); \
    split(maxenergies,maxenergies1,","); \
    for (i in ends1 ) {x= ends1[i] - begins1[i] ;\
        if (x < 0) {x=x+maxenergies1[i] } ;\
        printf x "\n" ; \
    }\
} \
'
}

############### get the paths of each device #######################

x=$(find /sys/devices/virtual/powercap/intel-rapl -name "name")
drams=""
cores=""
uncores=""
for i in ${x[@]}; do
    s=$(cat $i)
    case $s in
    dram)
        drams+=${i%name}" "
        ;;
    core)
        cores+=${i%name}" "
        ;;
    uncore)
        uncores+=${i%name}" "
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
    MAXCORE=$(read_maxenergy $cores)
fi

if [ -n "$uncores" ]; then
    MAXUNCORE=$(read_maxenergy $uncores)
fi

############# get the  energy  before the begining of the command for each device #################

beginpkg=$(read_energy $pkgs)

if [ -n "$drams" ]; then
    begindram=$(read_energy $drams)
fi

if [ -n "$cores" ]; then
    begincore=$(read_energy $cores)
fi

if [ -n "$uncores" ]; then
    beginuncore=$(read_energy $uncores)
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

if [ -n "$uncores" ]; then
    enduncore=$(read_energy $uncores)
fi

## calculate the differences

duration=$((($endT - $beginT) / 1000))

enegypkg=$(calculate_energy $beginpkg $endpkg $MAXPKG)

if [ -n "$drams" ]; then
    energydram=$(calculate_energy $begindram $enddram $MAXDRAM)

fi

if [ -n "$cores" ]; then
    energycore=$(calculate_energy $begincore $endcore $MAXCORE)

fi

if [ -n "$uncores" ]; then
    energyuncore=$(calculate_energy $beginuncore $enduncore $MAXUNCORE)

fi

#### verbose mode
if [ -n "$verbose" ]; then
    pkgs=$(calculate_energy_verbose $beginpkg $endpkg $MAXPKG)
    pkgs=${pkgs%'0'}

    cpu=0
    for i in ${pkgs[@]}; do
        cpu=$((cpu + 1))
    done
    printf "\n"

    echo -n ' ---------------'
    for i in $(seq 1 $cpu); do
        echo -n '------------------'
    done
    printf "\n"

    printf "| Cpu name      | "
    x=$((cpu - 1))
    for i in $(seq 0 $x); do
        printf "%-15s | " "cpu $i"
    done
    printf "\n"

    echo -n ' ---------------'
    for i in $(seq 1 $cpu); do
        echo -n '------------------'
    done
    printf "\n"

    pkgs=${pkgs%'0'}
    printf "| Energy cpu    | "

    for i in ${pkgs[@]}; do
        printf "%-15d | " $i
    done
    printf "\n"

    if [ -n "$drams" ]; then
        printf "| Energy dram   | "
        drams=$(calculate_energy_verbose $begindram $enddram $MAXDRAM)
        drams=${drams%'0'}
        for i in ${drams[@]}; do
            printf "%-15d | " $i
        done
        printf "\n"
    fi

    if [ -n "$cores" ]; then
        printf "| Energy core   | "
        cores=$(calculate_energy_verbose $begincore $endcore $MAXCORE)
        cores=${cores%'0'}
        for i in ${cores[@]}; do
            printf "%-15d | " $i
        done
        printf "\n"
    fi

    if [ -n "$uncores" ]; then
        printf "| Energy uncore | "
        uncores=$(calculate_energy_verbose $beginuncore $enduncore $MAXUNCORE)
        uncores=${uncores%'0'}
        for i in ${uncores[@]}; do
            printf "%-15d | " $i
        done
        printf "\n"
    fi
    echo -n ' ---------------'
    for i in $(seq 1 $cpu); do
        echo -n '------------------'
    done
    printf "\n\n"
fi

############ all results
echo "Global measures"
printf "Execution time    : %15d us\n" $duration

printf 'Energy cpu        : %15d uj\n' $enegypkg

if [ -n "$drams" ]; then

    printf 'Energy dram       : %15d uj\n' $energydram

fi

if [ -n "$cores" ]; then

    printf 'Energy core-cpu   : %15d uj\n' $energycore

fi
if [ -n "$uncores" ]; then

    printf 'Energy uncore-cpu : %15d uj\n' $energyuncore

fi
