#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script automatically cleans the results of executing "Text_Generator.sh" or "Execute_All_Case_Studies.sh"
#Usage: ./Cleaner.sh

rm -rf *_files   #Removes Test_Generator output
rm -rf Case_Studies_Executed  #Removes Execute_All_Case_Studies output
rm -rf Code_Coverage_Executed #Removes Execute_All_Code_Coverage output
rm -rf Case_Studies_Time_Measures #Removes Time_Script output