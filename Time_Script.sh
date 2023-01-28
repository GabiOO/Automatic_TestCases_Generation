#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script executes the Test_Generator x times for each case study to take time measures; creation, integration, compilation and execution 
#Prerequisite: compile the LAL_Test_Oracle project with Verbose = False in Config.ads, as well as Ada_Test_Generator.cpp with verbose = false,
#also, comment in Test_Generator the lines where gcov is called since we just aim to measure the creation+execution time of the unit tests. 

#Usage: ./Time_Script.sh <number_of_executions_per_case_study> <random_seed(only used if random testing)> 
#Example: ./Time_Script.sh 15 0 

number_of_executions=$1
random_seed=$2
index=1

files_dir="Case_Studies_Time_Measures_$random_seed"

rm -rf $files_dir #Cleaning previous executions

mkdir $files_dir #This folder will contain the reults of executing this script

#Next, we need to create the files that will contain the reports for each case study
echo ";AcceptOffer;;;;;;;" >> Time_Measure_AcceptOffer.csv
echo ";Sign;;;;;;;" >> Time_Measure_Sign.csv
echo ";In_Unit_Square;;;;;;;" >> Time_Measure_In_Unit_Square.csv
echo ";Compute_Speed;;;;;;;" >> Time_Measure_Compute_Speed.csv
echo ";Search;;;;;;;" >> Time_Measure_Search.csv
echo ";To_Green;;;;;;;" >> Time_Measure_To_Green.csv
echo ";To_Red;;;;;;;" >> Time_Measure_To_Red.csv
echo ";To_Yellow;;;;;;;" >> Time_Measure_To_Yellow.csv

#Then, we execute each case study as much times as desired by the user
while [ $index -le $number_of_executions ]; do
    echo "######################## Execution Number: $index"

    echo "------------------------Case Study 1: PriceVariable.ads with function AcceptOffer"
    if [ -d "AcceptOffer_files" ]; then rm -Rf AcceptOffer_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh PriceVariable.ads AcceptOffer 500 PriceVariable.adb false $random_seed #Verbose = false in Test_Generator.sh
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_AcceptOffer.csv

    echo "-----------------------Case Study 2.1: region_checks.ads with function Sign"
    if [ -d "Sign_files" ]; then rm -Rf Sign_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh region_checks.ads Sign 500 region_checks.adb false $random_seed
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_Sign.csv

    echo "-----------------------Case Study 2.2: region_checks.ads with function In_Unit_Square" 
    if [ -d "In_Unit_Square_files" ]; then rm -Rf In_Unit_Square_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh region_checks.ads In_Unit_Square 250 region_checks.adb false $random_seed
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_In_Unit_Square.csv

    echo "------------------------Case Study 3: simple_trajectory.ads with procedure Compute_Speed"
    if [ -d "Compute_Speed_files" ]; then rm -Rf Compute_Speed_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh simple_trajectory.ads Compute_Speed 500 simple_trajectory.adb false $random_seed
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_Compute_Speed.csv

    echo "------------------------Case Study 4: binary_search.ads with procedure Search" 
    if [ -d "Search_files" ]; then rm -Rf Search_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh binary_search.ads Search 500 binary_search.adb false $random_seed
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_Search.csv

    echo "-----------------------Case Study 5.1: road_traffic.ads with function To_Green" 
    if [ -d "To_Green_files" ]; then rm -Rf To_Green_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh road_traffic.ads To_Green 1000 road_traffic.adb false $random_seed
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_To_Green.csv

    echo "-----------------------Case Study 5.2: road_traffic.ads with function To_Red"
    if [ -d "To_Red_files" ]; then rm -Rf To_Red_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh road_traffic.ads To_Red 1000 road_traffic.adb false $random_seed
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_To_Red.csv

    echo "-----------------------Case Study 5.3: road_traffic.ads with function To_Yellow" 
    if [ -d "To_Yellow_files" ]; then rm -Rf To_Yellow_files; fi
    start=`date +%s.%N`
    ./Test_Generator.sh road_traffic.ads To_Yellow 1000 road_traffic.adb false $random_seed
    end=`date +%s.%N`
    runtime=$( echo "$end - $start" | bc -l )
    echo ";$runtime" >> Time_Measure_To_Yellow.csv

    let "index=index+1"
done

mv AcceptOffer_files $files_dir   #Moving the last execution to a common folder
mv Sign_files $files_dir
mv In_Unit_Square_files $files_dir
mv Compute_Speed_files $files_dir
mv Search_files $files_dir
mv To_Green_files $files_dir
mv To_Yellow_files $files_dir
mv To_Red_files $files_dir

mv Time_Measure*.txt $files_dir   #Moving the reports to a common folder

echo "Done..."