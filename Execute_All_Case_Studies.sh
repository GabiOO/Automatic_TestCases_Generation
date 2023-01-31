#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script automatically generates tests for all of our case studies
#Usage: ./Execute_All_Case_Studies.sh <max_number_of_solutions(default=1)>
#Example: ./Execute_All_Case_Studies.sh 1 , applies base case

max_solutions=${1:-1}  #1 by default, base case

mkdir Case_Studies_Executed

echo "------------------------Case Study 1: PriceVariable.ads with function AcceptOffer"
./Test_Generator.sh PriceVariable.ads AcceptOffer $max_solutions PriceVariable.adb 
mv AcceptOffer_files Case_Studies_Executed

read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "-----------------------Case Study 2: region_checks.ads with functions Sign, In_Unit_Square"
./Test_Generator.sh region_checks.ads Sign $max_solutions region_checks.adb 
mv Sign_files Case_Studies_Executed
echo ""
./Test_Generator.sh region_checks.ads In_Unit_Square $max_solutions region_checks.adb 
mv In_Unit_Square_files Case_Studies_Executed

read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "------------------------Case Study 3: simple_trajectory.ads with procedure Compute_Speed"
./Test_Generator.sh simple_trajectory.ads Compute_Speed $max_solutions simple_trajectory.adb 
mv Compute_Speed_files Case_Studies_Executed

read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "------------------------Case Study 4: binary_search.ads with procedure Search"
./Test_Generator.sh binary_search.ads Search $max_solutions binary_search.adb 
mv Search_files Case_Studies_Executed

read -n1 -s -p $'\n##########---------------Press any key to continue with the next case Study-------------##############\n' key

echo "##########################################################################################"
echo "-----------------------Case Study 5: road_traffic.ads with functions To_Green, To_Red, To_Yellow"
./Test_Generator.sh road_traffic.ads To_Green $max_solutions road_traffic.adb 
mv To_Green_files Case_Studies_Executed
echo ""
./Test_Generator.sh road_traffic.ads To_Red $max_solutions road_traffic.adb 
mv To_Red_files Case_Studies_Executed
echo ""
./Test_Generator.sh road_traffic.ads To_Yellow $max_solutions road_traffic.adb 
mv To_Yellow_files Case_Studies_Executed