#! /bin/bash
rapl='/sys/devices/virtual/powercap/intel-rapl/'

max_energies=()
for socket in $(ls $rapl | egrep 'intel-rapl'); do
    energy=$(cat $rapl/$socket/max_energy_range_uj)
    max_energies+=($energy)
done

begin_energies=()
for socket in $(ls $rapl | egrep 'intel-rapl'); do
    energy=$(cat $rapl/$socket/energy_uj)
    begin_energies+=($energy)
done

beginT=$(date +"%s%N")
$@

endT=$(date +"%s%N")
end_energies=()
for socket in $(ls $rapl | egrep 'intel-rapl'); do
    energy=$(cat $rapl/$socket/energy_uj)
    end_energies+=($energy)
done

duration=$((($endT - $beginT) / 1000000))

energies=()
for i in "${!end_energies[@]}"; do
    energy=$(((end_energies[$i] - begin_energies[$i]) / 1000))
    energies+=($energy)
done

real_energies=()
for i in "${!energies[@]}"; do
    if [[ ${energies[i]} -le 0 ]]; then
        energy=$((${energies[i]} + ${max_energies[i]}))
    else
        energy=${energies[i]}
    fi
    real_energies+=($energy)
done

echo 'execution time' : $duration'ms'

for i in ${!real_energies[@]}; do
    echo "socket $i : ${real_energies[i]}mJ"
done

sum=0
for e in ${real_energies[@]}; do
    sum=$((sum + e))
done

echo 'total energy : '$sum'mJ'
