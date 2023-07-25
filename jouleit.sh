#!/bin/bash
help() {
    cat <<EOF
Usage: jouleit [-n <iterations>] [-s <socket>] [-b] [-c] [-l] [-a] [-o <outputfile>]

Measure energy consumption of a system.

Options:
    -n <iterations>  Measure energy consumption for a specified number of iterations then print the output in a single csv file .
    -s <sockets>     a list of sockets to measure energy consumption for separated by , .
    -b               Output data in binary format <key:value>.
    -c               Output data in CSV format.
    -l               List all domains.
    -g               aggregate the  energy consumption for all sockets per component.
    -o <outputfile>  Write output to a file.
    -h               Show this help message and exit.

Examples:
    Measure energy consumption for all sockets:
        jouleit -a

    Measure energy consumption for socket 0:
        jouleit -s 0

    Measure energy consumption for 10 iterations:
        jouleit -n 10

    Measure energy consumption for all sockets and output data in CSV format:
        jouleit -a -c
EOF
}
#utils functions

# Function to sort lines of data by the first and fourth columns.
# the purpose is to sort the data by the path and the socket number.
# The function takes a string of data as input and returns the sorted data.
# Parameters:
#   $1: data - string of data to be sorted
# Returns:
#   The sorted data string.
sort_lines() {

    data=$1
    sorted_data=$(echo "$data" | tr ';' '\n' | sort -t',' -k1 | sort -t ',' -k4 | tr '\n' ';')
    sorted_data=${sorted_data::-1}
    echo "$sorted_data"
}

# Function to trim lines of data by removing the socket number and double underscores.
# The function takes a string of data as input and returns the trimmed data.
# Parameters:
#   $1: data - string of data to be trimmed
# Returns:
#   The trimmed data string.
trim_lines() {

    data=$1
    data=$(echo "$data" | tr ';' '\n' | sort | tr '\n' ';')
    data=$(echo $data | sed 's/[0-9]\+__//g')
    echo ${data%;}
    return 0
}

remove_keys() {
    data=$1
    data=$(echo $data | sed 's/[^;]\+://g')
    echo ${data%;}
    return 0
}

error() {
    echo "ERROR :" $1 >&2
    exit 1
}

retrieve_sockets() {
    sockets=$(ls /sys/devices/virtual/powercap/intel-rapl* | grep -oP '(?<=intel-rapl:)([0-9]+)')
    echo $sockets
}

# Generate man function
generate_man() {
    cat <<EOF
    JOULEIT(1)                          User Commands                         JOULEIT(1)

    NAME
        jouleit - measure energy consumption of a system

    SYNOPSIS
        jouleit [-n <iterations>] [-s <socket>] [-b] [-c] [-l] [-a] [-o <outputfile>]

    DESCRIPTION
        jouleit is a tool to measure the energy consumption of a system. It can be used to
        measure the energy consumption of a single socket or all sockets in the system.

        The options are as follows:

        -n <iterations>
            Measure energy consumption for a specified number of iterations.

        -s <socket>
            Measure energy consumption for a specified socket.

        -b     Output data in binary format.

        -c     Output data in CSV format.

        -l     List all domains.

        -g     Measure energy consumption for all sockets.

        -o <outputfile>
            Write output to a file.

    EXAMPLES
        Measure energy consumption for all sockets:

            jouleit -a

        Measure energy consumption for socket 0:

            jouleit -s 0

        Measure energy consumption for 10 iterations:

            jouleit -n 10

        Measure energy consumption for all sockets and output data in CSV format:

            jouleit -a -c

    SEE ALSO
        powerapi(1)

    AUTHORS
        Chakib Belgaid <chakib.belgaid@gmail.com>



    JOULEIT(1)                          User Commands                         JOULEIT(1)
EOF
}

# Read data
read_energy() {

    socket=$1
    components=$(find /sys/devices/virtual/powercap/intel-rapl/intel-rapl:$socket* -name "energy_uj" 2>/dev/null)
    data=""
    for component in ${components[@]}; do

        name=$(cat ${component%energy_uj}/name)
        energy=$(cat $component)
        data=$data$component,$name,$energy,$socket\;
    done
    data="${data%;}"
    echo $data
}

read_maxenergy() {
    socket=$1
    components=$(find /sys/devices/virtual/powercap/intel-rapl/intel-rapl:$socket* -name "energy_uj" 2>/dev/null)
    if [ -z "$components" ]; then
        error "No components found for socket $socket"
    fi
    data=""
    for component in ${components[@]}; do

        name=$(cat ${component%energy_uj}/name)
        energy=$(cat ${component%energy_uj}/max_energy_range_uj)
        data=$data$component,$name,$energy,$socket\;
    done
    data="${data%;}"
    echo $data
}

read_all_energy() {
    sockets=$1
    timestamp=$(date +"%s%6N")
    data=""
    for socket in ${sockets[@]}; do
        data=$data";"$(read_energy $socket)
    done
    # data="${data#*;}"
    data="global:/,DURATION,$timestamp$,99998,${data%;}"

    echo $data
}

read_all_maxenergy() {
    sockets=$1
    data=""
    for socket in ${sockets[@]}; do
        data=$data";"$(read_maxenergy $socket)
    done
    data="global:/,DURATION,0,99998,${data%;}"
    data=$(sort_lines "$data")
    echo $data

}

# Calculate the energyies

calculate_energy() {
    begins=$1
    ends=$2
    maxenergies=$3
    begins=$(sort_lines "$begins")
    ends=$(sort_lines "$ends")
    maxenergies=$(sort_lines "$maxenergies")
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
        socket_number[datamax[1]] =datamax[4]
    }      


    for (i in names ){

        x = energiesends[i] - energiesbegins[i]
        if (x < 0 )
            {
                x=x+energiesmax[i]
            }
        printf i","names[i]","x","socket_number[i]";" 
        }

    }')
    energies="${energies%;}"
    energies=$(echo $energies | sed -r 's/package-([0-9]+)/cpu/g')
    energies=$(sort_lines "$energies")
    echo $energies

}

########################### list the domains ##############################################

list_domains() {
    dt=$1
    dt=$(echo $dt | sed -r 's/package-([0-9]+)/cpu/g')
    domains=$(echo | awk -v data=$dt 'BEGIN \
    {   rank=0
        split(data,data1,";");
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=line1[4]
            if (cpu < 9998 ) {
                name=name"_"cpu
            }
            name = rank"__"name
            energies[name]=value
           rank=rank+1
        }
         for (key in energies ) {
            
           printf toupper(key)";"
        }
        printf rank"__EXIT_CODE"
    }')

    domains=$(trim_lines "$domains")
    domains="${domains%;}"
    echo $domains
}

list_global_domains() {
    dt=$1
    dt=$(echo $dt | sed -r 's/package-([0-9]+)/cpu/g')
    # dt=$(sort_lines "$dt")
    domains=$(echo | awk -v data=$dt 'BEGIN \
    {
        rank=0
        split(data,data1,";");
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            if ( energies[name] == "") {
                # printf rank"__"name","
                energies[name]=rank"__"name
                rank=rank+1
            }
            # energies[name]=energies[name]+value

        }
         for (key in energies ) {
           printf toupper(energies[key])";"
        }
        printf rank"__EXIT_CODE"
    }')
    domains=$(trim_lines "$domains")
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

}

print_details() {
    data=$1
    # data=$(sort_lines "$data")
    echo | awk -v data=$data 'BEGIN \
    {   old_cpu=-1 
        split(data,data1,";");
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=line1[4]

            if (match(name, "package")) { name = "cpu" }
            name =toupper(name)
            if ( ! match(name,"DURATION|EXIT_CODE" )) {
                if (cpu != old_cpu) {
                    printf " ---------------------------------------------- \n"
                    old_cpu=cpu
                }
                printf "|   %-7s | %-10s | %-19.3f |\n" ,cpu,name,value/1000000
            }
        }
    }'
    echo " ---------------------------------------------- "
}

##############################################################

print_binarry() {
    data=$1
    data=$(sort_lines "$data")
    energies=$(echo | awk -v data=$data 'BEGIN \
    {   rank = 0
        split(data,data1,";");
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            cpu=path1[2]
            split(cpu,cpu1,"/")
            cpu=line1[4]
            if ((cpu != "" ) && (cpu < 9998 )) {
                name=name"_"cpu
            }
            name = rank"__"name
            energies[name]=value
           rank=rank+1
        }

        for (key in energies ) {
           printf toupper(key)":"energies[key]";"
        }


        
    }')
    energies="${energies%;}"
    energies=$(trim_lines "$energies")
    # energies="${energies%;}"
    echo $energies
}

###############################################
calculate_global() {
    data=$1
    # data=$(sort_lines "$data")
    res=$(echo | awk -v data=$data 'BEGIN \
    {
        split(data,data1,";");
        for (line in data1 )  {
            split(data1[line],line1,",");
            path=line1[1];
            name=line1[2];
            value=line1[3];
            split(path,path1,":")
            energies[name]=energies[name]+value
        }
        
        for (key in energies ) {
           printf   "global:/,"toupper(key)","energies[key]",;"
        }
    
    }')

    echo $res

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

    begin_energy=$(read_all_energy $sockets)
    ###############################################
    if [ -n "$outputfile" ]; then

        $($@ 2>&1 >>$outputfile)
        exit_code=$?
    else
        x=$($@)
        exit_code=$?
    fi
    ###############################################
    end_energy=$(read_all_energy $sockets)

    ### Calculate the energies

    energies=$(calculate_energy $begin_energy $end_energy $maxenergies)
    energies="${energies%;}"
    energies=$(echo $energies | sed -r 's/package-([0-9]+)/cpu/g')

    if [ -n "$aggregate" ]; then

        global_energies=$(calculate_global $energies)
        global_energies="${global_energies%;}"
        results=$global_energies
    else
        results=$energies
    fi

    results=$results";global:/,exit_code,"$exit_code,99999
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

############### main ###########

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
    maxenergies=$(echo $maxenergies)
    if [ -n "$aggregate" ]; then
        s=$(list_global_domains $maxenergies)

    else
        s=$(list_domains $maxenergies)
    fi
    # s=$(sort_lines "$s")
    echo $s
}
print_append_csv() {
    results=$1
    results=$(print_binarry $results)
    results=$(remove_keys "$results")
    echo $results
}
###############################
check_os() {
    #check if the os is linux
    if [ "$(uname)" != "Linux" ]; then
        echo "Sorry, this script is only supported on Linux."
        exit 1
    fi
}

check_rapl() {
    #check if the rapl is enabled
    if [ ! -d "/sys/devices/virtual/powercap/intel-rapl" ]; then
        echo "Sorry, RAPL is not enabled on this system."
        exit 1
    fi
    # check if i have the permission to read the rapl
    if [ ! -r "/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj" ]; then
        echo "Sorry, you don't have the permission to read the RAPL. please run the script with sudo."
        exit 1
    fi
}

check_gawk() {
    if ! command -v gawk &>/dev/null; then
        echo "gawk could not be found please install it using the command: sudo apt install gawk in debian or sudo yum install gawk in redhat based systems"
        exit 1
    fi
}

check_compatibility() {
    check_os
    check_rapl

}
######

# the option -v
mode="terminal"
socket=""
iterations=""
sockets=$(retrieve_sockets)
sockets=(${sockets//,/ })
while getopts "gbcln:o:s:h" o; do
    case "${o}" in
    g)
        aggregate="True"
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
        sockets=${OPTARG}
        sockets=(${sockets//,/ })
        if [ ${#sockets[@]} -eq 0 ]; then
            error "please enter a valid socket number"
        fi
        for socket in ${sockets[@]}; do
            if ! [[ $socket =~ ^[0-9]+$ ]]; then
                error "please enter a valid socket number"
            fi
        done
        ;;
    n)
        mode="repeat"
        iterations=${OPTARG}
        ;;
    o)
        output="True"
        outputfile=${OPTARG}
        ;;
    h)
        help
        exit 0
        ;;
    esac

done

shift $((OPTIND - 1))

check_compatibility
maxenergies=$(read_all_maxenergy $sockets)

if [ -n "$list_dom" ]; then
    header_csv
else

    main $@
    exit_code=$?
fi

exit $exit_code
