#!/bin/bash

# the option -v
mode="terminal"
socket=""
iterations=""
while getopts "n:s:bo:lca" o; do
    case "${o}" in
    a)
        allsockets="True"
        ;;
    b)
        mode="binarry"
        ;;
    c)
        mode="csv"
        ;;
    l)
        list_dom="True"
        ;;
    s)
        socket=${OPTARG}
        ;;
    n)
        mode="repeat"
        iterations=${OPTARG}
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

    socket=$1
    components=$(find /sys/devices/virtual/powercap/intel-rapl/intel-rapl:$socket* -name "energy_uj")

    data=""
    for component in ${components[@]}; do

        name=$(cat ${component%energy_uj}/name)
        energy=$(cat $component)
        data=$data$component,$name,$energy\;
    done
    timestamp=$(date +"%s%6N")
    data="global:/,duration,$timestamp;${data%;}"
    echo $data
}

read_maxenergy() {
    socket=$1
    components=$(find /sys/devices/virtual/powercap/intel-rapl/intel-rapl:$socket* -name "energy_uj")

    data=""
    for component in ${components[@]}; do

        name=$(cat ${component%energy_uj}/name)
        energy=$(cat ${component%energy_uj}/max_energy_range_uj)
        data=$data$component,$name,$energy\;
    done
    data="global:/,duration,0;${data%;}"
    echo $data
}

# Calculate the energyies

calculate_energy() {
    begins=$1
    ends=$2
    maxenergies=$3
    energies=$(echo | awk -v begins=$begins -v ends=$ends -v maxenergies=$maxenergies 'BEGIN \
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

    }')
    energies="${energies%;}"
    energies=$(echo $energies | sed -r 's/package-([0-9]+)/cpu/g')
    echo $energies

}

########################### list the domains ##############################################

list_domains() {
    dt=$1
    dt=$(echo $dt | sed -r 's/package-([0-9]+)/cpu/g')
    domains=$(echo | awk -v data=$dt 'BEGIN \
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
           printf toupper(indices[i])";"
        }

    }')
    domains="${domains%;}"
    echo $domains
}

list_global_domains() {
    dt=$1
    dt=$(echo $dt | sed -r 's/package-([0-9]+)/cpu/g')
    domains=$(echo | awk -v data=$dt 'BEGIN \
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
           printf toupper(indices[i])";"
        }
    }')
    domains="${domains%;}"
    echo $domains
}

########################################################################
#Printing functions

print_time() {
    duration=$1
    echo ""
    echo " ----------------------------------------------"
    echo "|               execution time  (s)            |"
    echo " ----------------------------------------------"
    echo $duration | awk '{printf "|               %-30.3f |\n",$0/1000000}'
    echo " ---------------------------------------------- "

}

print_header() {

    printf "| Socket    | %-10s | %-19s |\n" "Component" "energy (J)"
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
            if ( ! match(name,"DURATION|EXIT_CODE" )) {
                printf "| Socket %-3s| %-10s | %-19.3f |\n" ,cpu,name,value/1000000
            }
        }
    }'
    echo " ---------------------------------------------- "
}

##############################################################

print_binarry() {

    energies=$(echo | awk -v data=$1 'BEGIN \
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
        
           printf toupper(indices[i])";"energies[indices[i]]";"
        }
        
    }')
    energies="${energies%;}"
    echo $energies
}

print_append_csv() {

    energies=$(echo | awk -v data=$1 'BEGIN \
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
        
           printf energies[indices[i]]";"
        }
        
    }')
    energies="${energies%;}"
    echo $energies
}

###############################################
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

show_pretty() {
    energies=$1
    duration=${energies#*DURATION,}
    duration=${duration%%;*}
    print_time $duration
    print_header
    print_details $energies
}

####################################
get_raw_energy() {
    begin_energy=$(read_energy $socket)
    # beginT=$(date +"%s%N")

    ###############################################
    if [ -n "$outputfile" ]; then

        $@ 2>&1 >>$outputfile
        exit_code=$?
    else
        $@
        exit_code=$?
    fi
    ###############################################

    end_energy=$(read_energy $socket)

    ### Calculate the energies

    energies=$(calculate_energy $begin_energy $end_energy $maxenergies)
    energies="${energies%;}"
    energies=$(echo $energies | sed -r 's/package-([0-9]+)/cpu/g')

    global_energies=$(calculate_global $energies)
    global_energies="${global_energies%;}"

    if [ -n "$allsockets" ] || [ -n "$socket" ]; then
        results=$energies
    else
        results=$global_energies
    fi

    results=$results";global:/,exit_code,"$exit_code
    ## Visualisation
    echo $results
    return $exit_code
}

bulk() {
    filename=data$(date +%s).csv
    iterations=$((iterations - 1))
    header='iteration;'$(header_csv)
    echo $header >$filename

    for i in $(seq 0 1 $iterations); do
        results=$(get_raw_energy $@)
        x=$i";"$(print_append_csv $results)
        echo $x >>$filename
    done
    echo "The data is stored in the file $filename"

}

###############main ###########

main() {
    case "${mode}" in
    binarry)
        results=$(get_raw_energy $@)
        print_binarry $results
        exit_code=$?
        ;;
    csv)
        results=$(get_raw_energy $@)
        print_append_csv $results
        exit_code=$?
        ;;
    repeat)
        bulk $@
        ;;
    *)
        results=$(get_raw_energy $@)
        show_pretty $results
        exit_code=$?
        ;;
    esac
    # echo ""

    return $exit_code
}

header_csv() {
    maxenergies=$(echo $maxenergies | sed -r 's/package-([0-9]+)/cpu/g')
    if [ -n "$allsockets" ]; then
        s=$(list_domains $maxenergies)
    else
        s=$(list_global_domains $maxenergies)
    fi
    echo $s";EXIT_CODE"
}

###############################
maxenergies=$(read_maxenergy $socket)

if [ -n "$list_dom" ]; then
    header_csv
else

    main $@
    exit_code=$?
fi

exit $exit_code
