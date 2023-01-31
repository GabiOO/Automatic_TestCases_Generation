#!/bin/bash

#Author: Gabriel Olea Olea
#Description: this script generates tests automatically for a target function given the specification where it belongs and the package body

#NOTE that the body file is NOT used for generating the test cases, but later to integrate the tests generated

#Usage: ./Test_Generator.sh <specification_file> <target_function> <max_num_solutions_to_generate> <body_file> [verbose(default=True)] [random_seed(default=0)]
#Example: ./Test_Generator.sh PriceVariable.ads AcceptOffer 1 PriceVariable.adb false 0

#Argument storing
spec_file=$1
function_name=$2
max_solutions=$3 
body_file=$4
verbose=${5:-true}  #true by default
random_seed=${6:-0}  #0 by default, only used if random oracle enabled

#First we use libadalang to create the .py file with constraints for Z3
files_dir="${function_name}_files"
mkdir -p $files_dir
if [ $verbose = true ]; then
    time ./LAL_Test_Oracle/obj/main $spec_file $function_name $max_solutions $random_seed
else
    ./LAL_Test_Oracle/obj/main $spec_file $function_name $max_solutions $random_seed
fi

isolated_info="${function_name}-IsolatedInfo.txt"
test_oracle="${function_name}-Test_Oracle.py"
mv $isolated_info ./$files_dir
mv $test_oracle ./$files_dir

if [ $verbose = true ]; then
    echo "" #New line
    echo "Z3py Test Oracle for the target function $function_name created"
fi

#Next, we execute the .py file to obtain the raw tests (input and expected output)
cd $files_dir
if [ $verbose = true ]; then
    time python ./$test_oracle
    echo "" #New line
    echo "Execution of the test oracle completed"
    echo "" #New line 
else
    python ./$test_oracle
fi
 
#Once we have the raw tests and the traslation from libadalang, we create the Unit Tests in SPARK
test_dir="_test"
mkdir -p $test_dir 

harness_dir="harness"
mkdir -p $test_dir/$harness_dir 

test_cases_dir="test_cases"
mkdir -p $test_dir/$test_cases_dir 

raw_tests="${function_name}-RawTests.txt"

if [ $verbose = true ]; then
    time ../Ada_Test_Creator/Test_Creator $isolated_info $raw_tests 
    echo "" #New line
    echo "Unit tests created"
else
    ../Ada_Test_Creator/Test_Creator $isolated_info $raw_tests 
fi


#After that, we create the src and obj directories for the project with the test harness, compile and execute the tests
mkdir -p src obj
mv $test_dir ./src
cp ../Case_Studies/$spec_file ./src #Spec file
cp ../Case_Studies/$body_file ./src #Body file

if [ $verbose = true ]; then
    echo "" #New line
    echo "The test harness has been created"
    read -n1 -s -p $'\nPress any key to compile and execute the tests...\n' key  
    echo "----------------Compiling----------------"
fi

#Compiling the project
gpr_file=`find . -name *.gpr`
gpr_file=${gpr_file:2} #Gets rid of the "./"
gpr_route="\GNAT\2021\projects\Test_Generator\\$files_dir\\$gpr_file"
main_adb_route="\GNAT\2021\projects\Test_Generator\\$files_dir\src\_test\harness\\${function_name}_Harness.adb"
aunit_route="\GNAT\2021\include\aunit"
gprbuild -d -PC:$gpr_route -XAUNIT_PATH=C:$aunit_route C:$main_adb_route

#Executing the tests
if [ $verbose = true ]; then
    echo "" #New line
    echo "----------------Executing the tests----------------"
fi
main_exe=`find ./obj -name *.exe`
main_exe=${main_exe:6} #Gets rid of the "./obj/"

if [ $verbose = true ]; then
    time ./obj/$main_exe #It also measures the time spent to execute the tests

    read -n1 -s -p $'\nPress any key to execute gcov...\n' key
    echo "----------------GCOV REPORT----------------"
else
    ./obj/$main_exe
    echo ""
fi

#----------Comment the following section when executing time measures
gcov -fbco ./obj ./src/$body_file  #with branch coverage, just a brief summary 

html_reports_dir="html_coverage_reports"
mkdir $html_reports_dir
cd $html_reports_dir
gcovr -r .. -g --html -o coverage.html --html-details  #-g to use existing gcov files 