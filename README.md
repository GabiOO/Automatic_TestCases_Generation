Requirements: You need to install GNATStudio, python version 3.0 or higher (along with the modules z3-solver, numpy and random) and gcov/gcovr. It is also necessary to create an specific file hierarchy inside GNAT and a Bash Interpreter.

1) Install GNATStudio (the free version would do): \\https://www.adacore.com/gnatpro/toolsuite/gnatstudio

2) Install Python with the modules numpy, random and z3-solver: \\https://pypi.org/project/z3-solver
   Personally, I use Python 3.10.8 but any version higher or equal to 3 would do, versions 2 or lower have a different 'string' treatment.

3) In respect to gcov/gcovr, gcov comes with the basic gcc package but gcovr does require an installation: https://gcovr.com/en/stable/installation.html

4) Once GNATStudio is installed, it is necessary to create the following file hierarchy in GNAT: '/GNAT/2021/projects/Test_Generator/'

5) Finally, as for the Bash Interpreter, I recommend https://gitforwindows.org/

Once the previous requirements are met, you should download the content of the repository and place it inside the folder: '/GNAT/2021/projects/Test_Generator/'.

Since GitHub do not support heavy files, the executable of the project 'LAL_Test_Oracle' must be compiled before use: open the LAL_Test_Oracle.gpr file isnide GNATSTudio and compile it.

Finally, return to the main folder and execute the scipt 'Execute_All_Case_Studies.sh'.
