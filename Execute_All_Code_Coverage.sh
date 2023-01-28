#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script automatically generates enough test cases to achieve a certain statement coverage for all of our case studies
#Usage: ./Execute_All_Code_Coverage.sh <statemente_coverage_desired(%)> [<"random">]
#Example: ./Execute_All_Code_Coverage.sh 100 , imposes 100% statement coverage on every case study using our constraint oracle
#         ./Execute_All_Code_Coverage.sh 100 random, imposes 100% statement coverage on every case study using our random oracle

coverage_goal=$1  #Coverage goal

files_dir="Constraint_Oracle_Code_Coverage"
if [ $# -eq 2 ]; then
    files_dir="Random_Oracle_Code_Coverage"
fi
mkdir $files_dir

echo "------------------------Case Study 1: PriceVariable.ads with function AcceptOffer, statement coverage goal: $coverage_goal"
if [ $# -eq 1 ]; then #Constraint Oracle
    ./Code_Coverage_Script.sh PriceVariable.ads AcceptOffer PriceVariable.adb $coverage_goal
    mv AcceptOffer_Coverage_files $files_dir
else #Random Oracle
    ./Code_Coverage_Script.sh PriceVariable.ads AcceptOffer PriceVariable.adb $coverage_goal random
    mv AcceptOffer_Random_Coverage_files $files_dir
fi

#read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "-----------------------Case Study 2: region_checks.ads with functions Sign, In_Unit_Square, statement coverage goal: $coverage_goal"
if [ $# -eq 1 ]; then #Constraint Oracle
    ./Code_Coverage_Script.sh region_checks.ads Sign region_checks.adb $coverage_goal
    mv Sign_Coverage_files $files_dir

    echo ""

    ./Code_Coverage_Script.sh region_checks.ads In_Unit_Square region_checks.adb $coverage_goal
    mv In_Unit_Square_Coverage_files $files_dir

else #Random Oracle
    ./Code_Coverage_Script.sh region_checks.ads Sign region_checks.adb $coverage_goal random
    mv Sign_Random_Coverage_files $files_dir

    echo ""

    ./Code_Coverage_Script.sh region_checks.ads In_Unit_Square region_checks.adb $coverage_goal random
    mv In_Unit_Square_Random_Coverage_files $files_dir
fi

#read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "------------------------Case Study 3: simple_trajectory.ads with procedure Compute_Speed, statement coverage goal: $coverage_goal"
if [ $# -eq 1 ]; then #Constraint Oracle
    ./Code_Coverage_Script.sh simple_trajectory.ads Compute_Speed simple_trajectory.adb $coverage_goal
    mv Compute_Speed_Coverage_files $files_dir
else #Random Oracle
    ./Code_Coverage_Script.sh simple_trajectory.ads Compute_Speed simple_trajectory.adb $coverage_goal random
    mv Compute_Speed_Random_Coverage_files $files_dir
fi

#read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "------------------------Case Study 4: binary_search.ads with procedure Search, statement coverage goal: $coverage_goal"
if [ $# -eq 1 ]; then #Constraint Oracle
    ./Code_Coverage_Script.sh binary_search.ads Search binary_search.adb $coverage_goal
    mv Search_Coverage_files $files_dir
else #Random Oracle
    ./Code_Coverage_Script.sh binary_search.ads Search binary_search.adb $coverage_goal random
    mv Search_Random_Coverage_files $files_dir
fi

#read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "-----------------------Case Study 5: road_traffic.ads with functions To_Green, To_Red, To_Yellow, statement coverage goal: $coverage_goal"
if [ $# -eq 1 ]; then #Constraint Oracle
    ./Code_Coverage_Script.sh road_traffic.ads To_Green road_traffic.adb $coverage_goal
    mv To_Green_Coverage_files $files_dir

    echo ""

    ./Code_Coverage_Script.sh road_traffic.ads To_Red road_traffic.adb $coverage_goal
    mv To_Red_Coverage_files $files_dir

    echo ""

    ./Code_Coverage_Script.sh road_traffic.ads To_Yellow road_traffic.adb $coverage_goal
    mv To_Yellow_Coverage_files $files_dir

else #Random Oracle
    ./Code_Coverage_Script.sh road_traffic.ads To_Green road_traffic.adb $coverage_goal random
    mv To_Green_Random_Coverage_files $files_dir

    echo ""

    ./Code_Coverage_Script.sh road_traffic.ads To_Red road_traffic.adb $coverage_goal random
    mv To_Red_Random_Coverage_files $files_dir

    echo ""

    ./Code_Coverage_Script.sh road_traffic.ads To_Yellow road_traffic.adb $coverage_goal random
    mv To_Yellow_Random_Coverage_files $files_dir    
fi
