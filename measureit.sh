#!/bin/bash




PKG0='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj'
MAXPKG0='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj'
# DRAM0='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj'
# PKG1='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:1/energy_uj'
# DRAM1='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:1/intel-rapl:1:0/energy_uj'

while getopts "v" o; do
    case "${o}" in
        v) 
            verbose="True"
        ;;   
        esac
done
shift $((OPTIND-1))


beginT=` date +"%s%N"`
beginPKG0=` cat $PKG0`
# beginDRAM0=` cat $DRAM0`
# beginPKG1=` cat $PKG1`
# beginDRAM1=` cat $DRAM1`
if [[ -n $verbose ]] 
then 
/usr/bin/time -apv $@
else
$@
fi

endT=` date +"%s%N"`
endPKG0=` cat $PKG0`
# endDRAM0=` cat $DRAM0`
# endPKG1=` cat $PKG1`
# endDRAM1=` cat $DRAM1`

duration=$((($endT - $beginT)/1000000))

pkg0=$((($endPKG0-$beginPKG0)/1000))

if [[ $pkg0 -le 0 ]]
then 
    pkg0=$(($pkg0 + $MAXPKG0))
fi 

# pkg1=$((($endPKG1-$beginPKG1)/1000))
# dram0=$((($endDRAM0-$beginDRAM0)/1000))
# dram1=$((($endDRAM1-$beginDRAM1)/1000))

# pkg=$(($pkg0+$pkg1))
# dram=$(($dram0+$dram1))

# echo 'duration (ms)'   $duration
if [[ -z $verbose ]] 
then
    echo '      duration (ms):'   $duration 
fi 

echo '      energy (mJ):'        $pkg0
# echo dram       $dram
