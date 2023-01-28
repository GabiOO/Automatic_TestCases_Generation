#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script automatically measures statement coverage up to a desired point, increasing the number of tests step by step
#Usage: ./Code_Coverage_Script.sh <specification_file> <target_function> <body_file> <statement_coverage_desired(%)> [<"random">] 
#Example: ./Code_Coverage_Script.sh PriceVariable.ads AcceptOffer PriceVariable.adb 100, if constraint oracle enabled
#         ./Code_Coverage_Script.sh PriceVariable.ads AcceptOffer PriceVariable.adb 100 random, if random oracle enabled

#Argument storing
spec_file=$1
function_name=$2
body_file=$3
coverage_goal=$4

random_seeds=(0)
if [ $# -eq 5 ]; then #Random seeds to use
    random_seeds=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14)
fi

#Folder that will contain the results
files_dir="${function_name}_Coverage_files"
common_files_dir="${function_name}_Random_Coverage_files" #Used if random oracle
if [ $# -eq 5 ]; then 
    mkdir -p $common_files_dir
fi


#Function that detects the code coverage achieved at a certain point
package_name=${spec_file%.*} #gets rid of the '.ads' at the end of the string
to_lowercase_package_name=${package_name,,} #We use ,, to covert into lowercase
to_lowercase_function_name=${function_name,,}

function code_coverage_detector {
    regex="Function '${to_lowercase_package_name}__${to_lowercase_function_name}'" 
    Line_Number=$(awk "/$regex/{print NR}" gcov_report.txt)  #Line number with the appearence of our regex (we made sure only one line matches)
    #The next line contains the statement coverage we are looking for
    let "Line_Number++"
    coverage=$(awk -F: "NR == $Line_Number {print}" gcov_report.txt)
    #Finally, we get rid of the characters that surround the coverage percentage we are looking for
    coverage=${coverage%\%*} #removes suffix starting with '%'
    coverage=${coverage#*\:} #removes prefix ending with ':'
}

################################################################################################################

#Array with all code coverages obtained from different seed executions, used if random oracle enabled
multiple_code_coverage_history=()

for random_seed in ${random_seeds[@]}; do

    #Actual and previous coverage achieved
    coverage=0
    previous_coverage=0

    #Condition to check wether coverage_goal was achieved or not (Floating point comparison)
    coverage_goal_NOT_achieved=`echo " $coverage < $coverage_goal " | bc` 

    #Condition to check wether code coverage has increased in comparison with the previous iteration (Floating point comparison)
    coverage_NOT_increased=`echo " $coverage == $previous_coverage " | bc` 

    #Array with the history of code coverage obtained
    code_coverage_history=(0)

    #Solution counter
    num_solutions=0

    #Max number of iterations allowed without an increment over the statement coverage achieved
    max_iters_wo_increment=30
    #Actual number of iterations without an increment over the statement coverage achieved
    iters_wo_increment=0

    while [[ $coverage_goal_NOT_achieved -eq 1 && $iters_wo_increment -lt $max_iters_wo_increment ]]; do  
        let "num_solutions++"
        echo "++++++++++++++++++++++++++++++++++++++++++...Actual number of solutions to generate: $num_solutions"

        if [ $# -eq 5 ]; then #Different naming for the random oracle, to show the seed
            files_dir="${function_name}_Random_Coverage_${random_seed}"
        fi
        mkdir -p $files_dir

        #First we use libadalang to create the .py file with constraints for Z3
        ./LAL_Test_Oracle/obj/main $spec_file $function_name $num_solutions $random_seed

        isolated_info="${function_name}-IsolatedInfo.txt"
        test_oracle="${function_name}-Test_Oracle.py"
        mv $isolated_info ./$files_dir
        mv $test_oracle ./$files_dir

        #Next, we execute the .py file to obtain the raw tests (input and expected output)
        cd $files_dir
        python ./$test_oracle

        #Once we have the raw tests and the traslation from libadalang, we create the Unit Tests in SPARK
        test_dir="_test"
        mkdir -p $test_dir 

        harness_dir="harness"
        mkdir -p $test_dir/$harness_dir 

        test_cases_dir="test_cases"
        mkdir -p $test_dir/$test_cases_dir 

        raw_tests="${function_name}-RawTests.txt"

        ../Ada_Test_Creator/Test_Creator $isolated_info $raw_tests 

        #After that, we create the src and obj directories for the project with the test harness, compile and execute the tests
        mkdir -p src obj
        mv $test_dir ./src
        cp ../Case_Studies/$spec_file ./src #Spec file
        cp ../Case_Studies/$body_file ./src #Body file

        #Compiling the project
        gpr_file=`find . -name *.gpr`
        gpr_file=${gpr_file:2} #Gets rid of the "./"
        gpr_route="\GNAT\2021\projects\Test_Generator\\$files_dir\\$gpr_file"
        main_adb_route="\GNAT\2021\projects\Test_Generator\\$files_dir\src\_test\harness\\${function_name}_Harness.adb"
        aunit_route="\GNAT\2021\include\aunit"
        gprbuild -d -PC:$gpr_route -XAUNIT_PATH=C:$aunit_route C:$main_adb_route

        #Executing the tests
        main_exe=`find ./obj -name *.exe`
        main_exe=${main_exe:6} #Gets rid of the "./obj/"

        ./obj/$main_exe

        #Finally we execute gcov and measure statement/branch coverage
        echo ""
        (gcov -fabco ./obj ./src/$body_file) >> gcov_report.txt        #with branch coverage, counting all blocks and a brief function summary
        code_coverage_detector                                         #Stores the actual coverage achieved
        code_coverage_history[${#code_coverage_history[@]}]=$coverage  #Append the last coverage obtained

        coverage_goal_NOT_achieved=`echo " $coverage < $coverage_goal " | bc` #Condition check
        if [ $coverage_goal_NOT_achieved -eq 1 ]; then 
            echo "------Actual statement coverage obtained: $coverage"
            #If this iteration WILL NOT BE THE LAST ITERATION due to the max_iters_wo_increment condition, 
            #we erase the whole content in order to produce new one for the next iteration
            coverage_NOT_increased=`echo " $coverage <= $previous_coverage " | bc`
            if ! [[ $iters_wo_increment -eq $(($max_iters_wo_increment - 1)) && $coverage_NOT_increased -eq 1 ]]; then
                cd ..
                rm -rf $files_dir  
            fi
            #Updates the iters_wo_increment if needed
            if [ $coverage_NOT_increased -eq 1 ]; then
                let "iters_wo_increment++"
            else
                iters_wo_increment=0 #Reset
            fi
            previous_coverage=$coverage  #Previous coverage update for the next iteration
        fi   
    done #While end

    #Once we reached the desired code coverage, we print the code coverage history and produce the html details 
    echo ";Code Coverage History for function $function_name;;;;;;;" >> code_coverage_history.csv
    for value in "${code_coverage_history[@]}"
    do
        echo ";$value" >> code_coverage_history.csv
        multiple_code_coverage_history[${#multiple_code_coverage_history[@]}]=$value #Add the value for possible multiple seeds
    done

    html_reports_dir="html_coverage_reports"
    mkdir $html_reports_dir
    cd $html_reports_dir
    gcovr -r .. -g --html -o coverage.html --html-details  #-g to use existing gcov files 

    if [ $# -eq 4 ]; then #Contraint Oracle
        echo "#######++++++++Statement Coverage of $coverage achieved, solutions required: $num_solutions" 
    else                #Random Oracle
        echo "#######++++++++Statement Coverage of $coverage achieved, solutions required: $num_solutions, random seed $random_seed" 
    fi

    cd ..; cd ..; #Back to the main folder
    if [ $# -eq 5 ]; then #If Random Oracle, we gather all seeds executed in a folder
        mv $files_dir $common_files_dir
    fi
done

if [ $# -eq 5 ]; then #If Random Oracle, we gather all code coverage in a single .csv
    csv_file="${function_name}_Random_Coverage_History.csv"

    #We iterate through the array and everytime we find a 0, we introduce a new table with the correspondent seed
    actual_seed=0

    for elem in "${multiple_code_coverage_history[@]}"
    do
        #Expression to check if a 0 was reached using floating point comparison
        new_table_seed=`echo " $elem == 0 " | bc`

        if [ $new_table_seed -eq 1 ]; then 
            echo ";;;;;;;;" >> $csv_file #Line break
            echo "; ${function_name} Random Seed $actual_seed ;;;;;;;" >> $csv_file
            let "actual_seed++" 
        fi
        echo ";$elem" >> $csv_file
    done

    mv $csv_file $common_files_dir
fi