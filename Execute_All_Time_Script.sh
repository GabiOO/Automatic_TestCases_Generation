#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script executes the Time_Script.sh with different random seeds, therefore it is meant to be used with the random oracle enabled
#If you want to take time measures on the constraint oracle,  
#Prerequisites: read "Time_Script.sh" prerequisites
#Usage: ./Execute_All_Time_Script.sh 
#Example: ./Execute_All_Time_Script.sh 

random_seeds=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14)   #Random seeds for random testing
num_executions=10

files_dir="Multiple_Random_Seeds_Time_Measures"
mkdir $files_dir

for elem in ${random_seeds[@]}
do   
    ./Time_Script.sh $num_executions $elem
    mv Case_Studies_Time_Measures_${elem} $files_dir
done