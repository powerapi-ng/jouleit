#!/bin/bash

assertEquals() {
    if [ "$1" == "$2" ]; then
        echo "OK"
    else
        echo "FAIL: $1 != $2"
    fi
}

sort_lines() {
    # sort the lines by the first column
    data=$1
    sorted_data=$(echo "$data" | tr ';' '\n' | sort -t',' -k1 | sort -t ',' -k4 | tr '\n' ';')
    sorted_data=${sorted_data::-1}
    echo "$sorted_data"
}

trim_lines() {
    data=$1
    data=$(echo "$data" | tr ';' '\n' | sort | tr '\n' ';')
    data=$(echo $data | sed 's/[0-9]\+__//g')
    echo ${data%;}
    return 0
}

remove_keys() {
    data=$1
    # data=$(echo "$data" | tr ';' '\n' | sort | tr '\n' ';')
    data=$(echo $data | sed 's/[^;]\+://g')
    echo ${data%;}
    return 0
}

# Test sort_lines function
test_sort_lines() {
    input="1,2,3;4,5,6;7,8,9"
    expected_output="1,2,3;4,5,6;7,8,9"
    output=$(sort_lines "$input")
    assertEquals "$expected_output" "$output"

    input="3,2,1;6,5,4;9,8,7"
    expected_output="3,2,1;6,5,4;9,8,7"
    output=$(sort_lines "$input")
    assertEquals "$expected_output" "$output"

    input="3,2,1;6,5,4;9,8,7;1,2,3"
    expected_output="1,2,3;3,2,1;6,5,4;9,8,7"
    output=$(sort_lines "$input")
    assertEquals "$expected_output" "$output"
}

# Test trim_lines function
test_trim_lines() {
    input="1__a;2__b;3__c"
    expected_output="a;b;c"
    output=$(trim_lines "$input")
    assertEquals "$expected_output" "$output"

    input="1__a;2__b;3__c;4__d"
    expected_output="a;b;c;d"
    output=$(trim_lines "$input")
    assertEquals "$expected_output" "$output"

    input="1__a;2__b;3__c;4__d;5__e"
    expected_output="a;b;c;d;e"
    output=$(trim_lines "$input")
    assertEquals "$expected_output" "$output"
    # BEGIN: 8f3c5d9gjwq1

    # END: 8f3c5d9gjwq1
}

# Test remove_keys function
test_remove_keys() {
    input="key1:value1;key2:value2;key3:value3"
    expected_output="value1;value2;value3"
    output=$(remove_keys "$input")
    assertEquals "$expected_output" "$output"

    input="key1:value1;key2:value2;key3:value3;key4:value4"
    expected_output="value1;value2;value3;value4"
    output=$(remove_keys "$input")
    assertEquals "$expected_output" "$output"

    input="key1:value1;key2:value2;key3:value3;key4:value4;key5:value5"
    expected_output="value1;value2;value3;value4;value5"
    output=$(remove_keys "$input")
    assertEquals "$expected_output" "$output"
}

test_sort_lines
test_trim_lines
test_remove_keys
