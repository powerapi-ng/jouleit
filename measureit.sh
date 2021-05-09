#!/bin/bash

# the option -v
mode="terminal"
while getopts "ao:lcv" o; do
    case "${o}" in
    v)
        verbose="True"
        ;;
    c)
        mode="csv"
        ;;
    a)
        mode="append"
        ;;
    l)
        list_dom="True"
        ;;
    o)
        output="True"
        outputfile=${OPTARG}
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
        split(maxenergies1[i],datamax,",")
        energiesmax[datamax[1]] =datamax[3]
    }      


    for (i in names ){

        x = energiesends[i] - energiesbegins[i]
        if (x < 0 )
            {
                x=x+energiesmax[i]
            }
        printf i","names[i]","x";" 
        }

    }'

}

#Printing functions

print_time() {
    duration=$1
    echo ""
    echo " ----------------------------------------------"
    echo "|               execution time  (us)           |"
    echo " ----------------------------------------------"
    printf "|               %-30d |\n" $duration
    echo " ---------------------------------------------- "

}

print_header() {

    printf "| Socket    | %-10s | %-19s |\n" "Component" "energy (uJ)"
    echo " ---------------------------------------------- "
}

print_details() {

    echo | awk -v data=$1 'BEGIN \
    {
        split(data,data1,";");
        asort(data1)
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=path1[2]
            split(cpu,cpu1,"/")
            cpu=cpu1[1]
            if (match(name, "package")) { name = "cpu" }
            name =toupper(name)
            printf "| Socket %-3s| %-10s | %-19d |\n" ,cpu,name,value
        }
    }'
    echo " ---------------------------------------------- "
}

print_csv() {

    echo | awk -v data=$1 'BEGIN \
    {
        split(data,data1,";");
        asort(data1)
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=path1[2]
            split(cpu,cpu1,"/")
            cpu=cpu1[1]
            energies[name,cpu]=value
           
        }
        asorti(energies,indices )
         for (i in indices ) {
        
           printf ";"toupper(indices[i])";"energies[indices[i]]
        }
        
    }'
}

print_append_csv() {

    echo | awk -v data=$1 'BEGIN \
    {
        split(data,data1,";");
        asort(data1)
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=path1[2]
            split(cpu,cpu1,"/")
            cpu=cpu1[1]
            energies[name,cpu]=value
           
        }
        asorti(energies,indices )
         for (i in indices ) {
        
           printf ";"energies[indices[i]]
        }
        
    }'
}

calculate_global() {

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
        
       asorti(energies,indices )
         for (i in indices ) {
           printf "global:/,"toupper(indices[i])","energies[indices[i]]";"
        }
    
    }'

}

list_global_domains() {
    echo -n duration
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
        
        asorti(energies,indices )
         for (i in indices ) {
           printf ";"toupper(indices[i])
        }
    }'

}

list_domains() {
    echo -n duration
    echo | awk -v data=$1 'BEGIN \
    {
        split(data,data1,";");
        asort(data1)
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=path1[2]
            split(cpu,cpu1,"/")
            cpu=cpu1[1]
            energies[name,cpu]=value
           
        }
        asorti(energies,indices )
         for (i in indices ) {
           printf ";"toupper(indices[i])
        }

    }'
}

get_raw_energy() {
    begin_energy=$(read_energy)
    beginT=$(date +"%s%N")

    ###############################################
    if [ -n "$outputfile" ]; then

        $@ 2>&1 >>$outputfile
        exit_code=$?
    else
        $@
        exit_code=$?
    fi
    ###############################################
    endT=$(date +"%s%N")
    end_energy=$(read_energy)

    ### Calculate the energies

    energies=$(calculate_energy $begin_energy $end_energy $maxenergies)
    duration=$((($endT - $beginT) / 1000))
    # Remove the last ;
    energies="${energies%;}"
    # Change package with CPU
    energies=$(echo $energies | sed -r 's/package-([0-9]+)/cpu/g')
    # calculat the global energy
    global_energies=$(calculate_global $energies)
    global_energies="${global_energies%;}"

    if [ -n "$verbose" ]; then
        results=$energies
    else
        results=$global_energies
    fi

    results=$results";global:/,exit_code,"$exit_code
    ## Visualisation
    case "${mode}" in

    csv)
        echo -n "duration;"$duration
        print_csv $results
        ;;
    append)
        echo -n $duration
        print_append_csv $results
        ;;
    *)
        show_pretty
        ;;
    esac
    echo ""

    return $exit_code
}

show_pretty() {

    print_time $duration
    print_header
    print_details $global_energies

    if [ -n "$verbose" ]; then
        print_details $energies
    fi
}

###############################
maxenergies=$(read_maxenergy)

if [ -n "$list_dom" ]; then
    maxenergies=$(echo $maxenergies | sed -r 's/package-([0-9]+)/cpu/g')
    if [ -n "$verbose" ]; then
        list_domains $maxenergies
    else
        list_global_domains $maxenergies
    fi
    echo ";EXIT_CODE"

else
    get_raw_energy $@
    exit_code=$?
fi

exit $exit_code
