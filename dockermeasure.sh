#!/bin/bash


######## 
#use this script if u want to monitor the inside of a docker container 
# install time --it will replace the defalut one to have more parameters 
#./dockermeasure.sh {-n name docker/image cmd  }

PKG0='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj'
MAXPKG0='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj'
DRAM0='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj'
# PKG1='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:1/energy_uj'
# DRAM1='/sys/devices/virtual/powercap/intel-rapl/intel-rapl:1/intel-rapl:1:0/energy_uj'

while getopts "n:" o; do
    case "${o}" in
        t)  
            name="True"
            dockerName=${OPTARG}
        ;;
        esac
done
shift $((OPTIND-1))
dockerImage=$1 
shift 

old_ENTRYPOINT=`docker inspect  --format='{{.ContainerConfig.Entrypoint}}' $dockerImage ` 
old_ENTRYPOINT=${old_ENTRYPOINT:1:-1}
beginT=` date +"%s%N"`
beginPKG0=` cat $PKG0`
# beginDRAM0=` cat $DRAM0`
# beginPKG1=` cat $PKG1`
# beginDRAM1=` cat $DRAM1`
if [[ -n $name ]] 
then 
# docker run --rm -it -v /usr/bin/time:/hostbin --entrypoint=/hostbin/time --name $dockername -apv  old_ENTRYPOINT $@ 
docker run --rm -it -v /usr/bin/time:/time --entrypoint="/time" --name $dockerName $dockerImage -apv  $old_ENTRYPOINT $@
else
docker run --rm -it -v /usr/bin/time:/time --entrypoint="/time" $dockerImage -apv  $old_ENTRYPOINT $@  
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
echo '      energy (mJ):'        $pkg0
# echo dram       $dram