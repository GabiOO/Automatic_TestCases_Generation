#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script counts all functions/procedures in the specification files of the spark examples provided at GNATStudio,
# and then, counts how many of those previous functions/procedures contain specifications including pre,Post or Contract_Cases.

#First we move to the directory containing all the spark examples
cd /c/GNAT/2021/share/examples/spark  

#Then we count all functions and procedures in every specification file
printf "....Functions found in all the spark example specifications....\n"
egrep --color -Rw '^[[:space:]]*function' */*\.ads    #egrep options: 'R' searches recursively, 'w' matches exact word
n_functions=$(egrep --color -Rw '^[[:space:]]*function' */*\.ads | wc -l)  #wc options: 'l' counts lines
printf "\n--------------------------------Total of: $n_functions functions.\n"

read -n1 -s -p $'\nPress any key to continue...\n' key  

printf "\n....Procedures found in all the spark example specifications....\n"
egrep --color -Rw '^[[:space:]]*procedure' */*\.ads    
n_procedures=$(egrep --color -Rw '^[[:space:]]*procedure' */*\.ads | wc -l)  
printf "\n--------------------------------Total of: $n_procedures procedures.\n"

read -n1 -s -p $'\nPress any key to continue...\n' key 

#Following that, we count how many specifications use Post and or Contract_Cases
printf "\n....Postconditions or Contract_Cases found in all the spark example specifications....\n"
egrep --color -Rw 'Post[[:space:]]*=>|Contract_Cases[[:space:]]*=>' */*\.ads    
n_post_contracts=$(egrep --color -Rw 'Post[[:space:]]*=>|Contract_Cases[[:space:]]*=>' */*\.ads | wc -l)  
printf "\n--------------------------------Total of: $n_post_contracts Postconditions or Contract_Cases.\n"

total_func_proced=$(($n_functions + $n_procedures))

#Finally, we do the analysis
printf "\n-------Therefore out of $total_func_proced functions/procedures, only $n_post_contracts have specifications containing Post and/or Contract_cases\n"

percentage_candidates=`echo "scale=2; $n_post_contracts / $total_func_proced * 100" | bc`

blue=$(tput setaf 4)
printf "\t${blue}Only $percentage_candidates%% of the functions/procedures are plausible candidates to apply the automatic generation tests method\n"


