with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers; Use Ada.Containers;

package body Z3py_Printer is

   --Procedure that prints the header for the program (author, z3 import, etc)
   procedure Print_Header is
   begin
      Put_Line("'''");
      Put_Line("Test Oracle developed by Gabriel Olea Olea, generated automatically");
      Put_Line("'''");
      New_Line;
      Put_Line("import numpy as np");
      Put_Line("from z3 import * #Z3 SMT constraint solver");
      New_Line;
      Put_Line("import sys #Output redirection"); --Redirecting the output
      Put_Line("path = ""./" & Target_Function_Name.First_Element & "-RawTests.txt""");
      Put_Line("sys.stdout = open(path, 'w')");
      New_Line;
      Put_Line("print(""-----" & Target_Function_Name.First_Element &" Raw Tests-----"")");
      New_Line;
      --Int support
      if Int_Support = True then
         Print_Int_Support;
      end if;
      --Array Support
      if Array_Support_Needed then
         Print_Array_Support;
      end if;
      --Next, we print functions support if needed
      if Target_Function_Name.First_Element = "Compute_Speed" then --Support for simple_trajectory.ads
         Print_Trajectory_Support;
      end if;
      if Target_Function_Name.First_Element = "To_Green" or
         Target_Function_Name.First_Element = "To_Red" or
         Target_Function_Name.First_Element = "To_Yellow" then --Support for road_traffic.ads
         Print_Road_Traffic_Support;
      end if;
      --Random test support
      if Random_Test = True then
         Print_Random_Support;
      end if;
      --Support for Boundary Analysis
      if Boundary_Analysis then
         Put_Line("#-----------------Boundary Analysis support");
         Put_Line("def abs(x):");
         Put_Line("   return If(x >= 0,x,-x)");
      end if;
      Put_Line("#---------------------------------------------------");
      Put_Line("set_option('smt.random_seed', "& Z3_Random_Seed'Image &")         #random seed");
      Put_Line("set_option(rational_to_decimal=True)    #decimal printing"); --Printing floats
      Put_Line("set_option(precision="& max_solutions'Image &"*10)    #enough float precision to avoid printing truncations"); --Float precision
      New_Line;
   end Print_Header;


   --Procedure that prints the general variables (Objects in SPARK)
   procedure Print_Objects is
   begin
      if not Obj_Z3.Is_Empty then
         Put_Line("#-----Objects the model might use");
         Print_String_Vector( Obj_Z3 );
         New_Line;
      end if;
   end Print_Objects;


   --Procedure that prints the model variables (Parameters of the target function in SPARK)
   procedure Print_Model_Variables is
   begin
      Put_Line("#-----Model Variables");
      Print_String_Vector( Params_Z3 );
      if not Delta_Param_Z3.Is_Empty then
         Put_Line("#Auxiliar variable for the 'delta' constraint");
         Print_String_Vector( Delta_Param_Z3 );
      end if;
      New_Line;
   end Print_Model_Variables;


   --Procedure that creates the Z3 solver
   procedure Print_Solver is
   begin
      Put_Line("#-----Solver creation");
      Put_Line( Target_Function_Name.First_Element & " = Solver()");
      New_Line;
   end Print_Solver;


   --Procedure that prints the implicit constraints for the model variables
   procedure Print_Implicit_Constraints is
   begin
      if not Implicit_Constraint_Z3.Is_Empty then
         Put_Line("#-----Implicit Constraints");
         for E of Implicit_Constraint_Z3 loop
            Put_Line( Target_Function_Name.First_Element & ".add(" & E & ")");
         end loop;
         New_Line;
      end if;
   end Print_Implicit_Constraints;


   --Procedure that prints the explicit constraints (Global Precondition)
   procedure Print_Precondition is
   begin
      if not Explicit_Constraint_Z3.Is_Empty then
         Put_Line("#-----Global Precondition");
         for E of Explicit_Constraint_Z3 loop --Note this vector usually contains just one String
            Put_Line( Target_Function_Name.First_Element & ".add(" & E & ")");
         end loop;
         New_Line;
      end if;
   end Print_Precondition;


   --Procedure that prints the local precondition associated to the contract case
   procedure Print_Contract_Case_Guard is
   begin
      Put_Line("print(""-----Case: " & Contract_Cases_Z3(actual_case) & "-----"")");
      Put_Line(Target_Function_Name.First_Element & ".push()    #Creates a new scope for this contract case");
      Put_Line( Target_Function_Name.First_Element & ".add(" & Contract_Cases_Guards_Z3(actual_case) & ")    #Local Precondition");
   end Print_Contract_Case_Guard;


   --Procedure that prints the contract case consequence (local postcodition) associated to the actual case
   procedure Print_Contract_Case_Consequence is
   begin
      if Contract_Cases_Consequences_Z3(actual_case).Condition_Type = Value then  --Expected Value
         Actual_Postcondition_Type := Value;
         Put_Line( "   expected_value = " & Contract_Cases_Consequences_Z3(actual_case).Condition.First_Element & "    #Local Postcondition");
      else  --Expected Behaviour, python will treat it as a String
         Actual_Postcondition_Type := Behaviour;
         Put_Line( "   expected_behaviour = """ & Contract_Cases_Consequences_Z3(actual_case).Condition.First_Element & """    #Local Postcondition");
      end if;
      actual_case := actual_case + 1;   --Update the contract case for the next iteration of the model
   end Print_Contract_Case_Consequence;


   --Procedure that prints the Postcondition (Global Postcondition) defining the expected value or behaviour
   procedure Print_Postcondition is
   begin
      if not Global_Postcondition_Z3.Condition.Is_Empty then
         if Global_Postcondition_Z3.Condition_Type = Value then  --Expected Value
            Actual_Postcondition_Type := Value;
            Put_Line( "   expected_value = " & Global_Postcondition_Z3.Condition.First_Element & "    #Postcondition");
         else  --Expected Behaviour, python will treat it as a String
            Actual_Postcondition_Type := Behaviour;
            Put_Line( "   expected_behaviour = """ & Global_Postcondition_Z3.Condition.First_Element & """    #Postcondition");
         end if;
      end if;
   end Print_Postcondition;


   --Procedure that prints the test vector for Z3
   procedure Print_Test_Vector is
      Many_Params : Boolean := Param_Names.Length > 1;
   begin
      Put("   test_vector = ");

      if Many_Params then --If there are more than one parameter, the test vector will be a python list
         Put("(");
      end if;

      for param in Param_Names.First_Index .. Param_Names.Last_Index loop
         if Params_Type_Treatment( param ) = "Array" then --Arrays and need special treatment
            Put("[ m[elem] for elem in " & Param_Names(param) & " ]");
         elsif Params_Type_Treatment( param ) = "Map" then --Maps and need special treatment
            Put("[ m[" & Param_Names(param) & "[key]] for key in " & Param_Names(param) & ".keys() ]");
         else  --Normal treatment
            Put("m[" & Param_Names(param) & "]");
         end if;

         if param /= Param_Names.Last_Index then
            Put(", ");
         end if;
      end loop;

      if Many_Params then --Closing the python list
         Put(")");
      end if;

      New_Line;
   end Print_Test_Vector;


   --Procedure that ensures different solutions for the next iteration of the Z3 model
   --Note that in order to obtain a different test vector, we would simply need one of its elements to change,
   --but if we want to obtain more variated test vectors, we can force all of the elements to be different using And
   procedure Print_Ensure_Different_Solutions is
      Many_Params : Boolean := Param_Names.Length > 1;
   begin
      Put("   " & Target_Function_Name.First_Element & ".add( ");

      if Many_Params then --If there are more than one parameter, we create an 'Or' clause
         --Since the procedure Compute_Speed contains a "None" variable solution (no constraint associated to that variable in the specification),
         --to ensure different solutions we need to impose an And clause instead
         if not ( Target_Function_Name.First_Element = "Compute_Speed" ) then
           Put("Or( ");
         else
           Put("And( ");
         end if;
      end if;

      for param in Param_Names.First_Index .. Param_Names.Last_Index loop
         if Params_Type_Treatment( param ) = "Array" then --Arrays need special treatment
            Put("Or( [elem != m[elem] for elem in " & Param_Names(param) & "] )");
         elsif Params_Type_Treatment( param ) = "Map" then --Maps need special treatment
            Put("Or( [" & Param_Names(param) & "[key] != m[" & Param_Names(param) & "[key]] for key in " & Param_Names(param) & ".keys()] )");
         else --Normal treatment
            Put( Param_Names(param) & " != m[" & Param_Names(param) & "]");
         end if;

         if param /= Param_Names.Last_Index then
            Put(", ");
         end if;
      end loop;

      if Many_Params then --Closing the parenthesis needed
         Put(") )");
      else
         Put(")");
      end if;

      New_Line;
   end Print_Ensure_Different_Solutions;


   --Procedure that prints the generation of the main body of the program
   procedure Print_Model is   --Note that ADA doesn't support multiline Strings...
   begin
      Put_Line("max_solutions = " & max_solutions'Image & "   #max num of tests to generate");
      Put_Line("num_solutions = 0   #counter of solutions");
      --Main loop
      Put_Line("while " & Target_Function_Name.First_Element & ".check() == z3.sat and num_solutions < max_solutions:");
      Put_Line("   m = " & Target_Function_Name.First_Element & ".model()");
      New_Line;
      --Creation of the test vector
      Print_Test_Vector;
      --Postcondition associated to the result of the function, it also defines the expected value or behaviour
      if not Contract_Cases_Z3.Is_Empty then
         Print_Contract_Case_Consequence; --Prints the actual contract case to be processed
      else
         Print_Postcondition;             --Prints the global postcondition to be processed
      end if;
      New_Line;
      --Printing the solution found
      if Actual_Postcondition_Type = Value then --Expected Value
         Put_Line("   print(""Test vector: "", test_vector, "", Expected value: "", expected_value)");
      else                                      --Expected Behaviour
         Put_Line("   print(""Test vector: "", test_vector, "", Expected behaviour: "", expected_behaviour)");
      end if;
      New_Line;
      Put_Line("   num_solutions = num_solutions + 1");
      --Ensuring different solutions for the next iterations
      Print_Ensure_Different_Solutions;
      --Restoring the previous scope if necessary
      if not Contract_Cases_Z3.Is_Empty then
         Put_Line(Target_Function_Name.First_Element & ".pop()    #Restores the previous scope");
      end if;
      New_Line;
   end Print_Model;


   --Procedure that prints a model that creates a default test vector negating the explicit pre of the target function
   procedure Print_Negate_Precondition_Model is
   begin
      if ( (Test_Negate_Precondition = True) and not Explicit_Constraint_Z3.Is_Empty ) then --If there is an explicit precondition, we can negate it
         Put_Line("print(""-----" & Target_Function_Name.First_Element &" Negate Precondition Test-----"")");
         Print_Solver;
         Print_Implicit_Constraints; --It is not interesting to negate the implicit preconditions
         Put_Line("#-----Negated Precondition");
         for E of Explicit_Constraint_Z3 loop --Note this vector usually contains just one String
            Put_Line( Target_Function_Name.First_Element & ".add( Not(" & E & ") )");
         end loop;
         New_Line;
         Put_Line("if " & Target_Function_Name.First_Element & ".check() == z3.sat: ");
         New_Line;
         Put_Line("   m = " & Target_Function_Name.First_Element & ".model()");
         --Creation of the test vector
         Print_Test_Vector;
         --We expect an error
         Put_Line("   expected_value = 'Error'");
         New_Line;
         --Printing the pair test_vector-expected_behaviour
         Put_Line("   print(""Test vector: "", test_vector, "", Expected value: "", expected_value)");
         New_Line;
         Put_Line("else: ");
         Put_Line("   print(""The negation of the precondition is unsatisfiable..."")");
      end if;
   end Print_Negate_Precondition_Model;


   --Procedure that prints a random test
   procedure Print_Random_Test is
   begin
      Put_Line("print(""-----" & Target_Function_Name.First_Element &" Random Testing-----"")");
      for index in 1 .. max_solutions loop
         --Random Test Vector creation
         Put_Line("random_test_vector = Random_Test_Vector()");
         --Random Expected Output random value ceation
         Put_Line("random_expected_output = Random_Expected_Output()");
         --Printing the random values generated
         Put_Line("print(""Test vector: "", random_test_vector, "", Expected random: "", random_expected_output)");
         New_Line;
      end loop;
   end Print_Random_Test;


   --******************* Z3py support functions **********************************

   --Procedure that prints the support for Integers boundaries
   procedure Print_Int_Support is
   begin
      Put_Line("#---Integer Boundaries support");
      Put_Line("MaxInt = " & MaxInt'Image);
      Put_Line("MinInt = " & MinInt'Image);
      New_Line;
   end Print_Int_Support;

   --Procedure that prints the support functions needed in python for testing simple_trajectory.ads
   procedure Print_Trajectory_Support is
   begin
      Put_Line("#---Simple Trajectory support functions");
      Put_Line("Num_Digits = " & Num_Digits'Image);
      Put_Line("set_option(precision = Num_Digits)    #decimal precision");
      New_Line;
      --This function emulates the 'Frame'Last' attribute call in Ada in simple_trajectory.ads
      Put_Line("Frame = ""Frame""   #Auxiliar variables");
      Put_Line("Drag_T = ""Drag_T""");
      Put_Line("def Last(x):");
      Put_Line("   if x == ""Frame"":");
      Put_Line("      return " & Implicit_Constraint_Map( "Frame_range_right" ) );
      Put_Line("   else:");
      Put_Line("      return " & Implicit_Constraint_Map( "Drag_T_range_right" ) );
      New_Line;
      --This is the natural translation of 'Ceiling' in python
      Put_Line("def Ceiling(x):");
      Put_Line("   import math as math");
      Put_Line("   return math.ceil(x)");
      New_Line;
      --This function is the natural translation of the auxilair function Invariant from simple_trajectory.ads
      Put_Line("def Invariant(n, speed):");
      Put_Line("   return And((-1)*n*Bound <= speed, speed <= n*Bound)");
      New_Line;
   end Print_Trajectory_Support;


   --Procedure that prints the support for road_traffic.ads functions
   procedure Print_Road_Traffic_Support is
   begin
      Put_Line("#---Road Traffic support functions");
      Put_Line("def Left(x):"); --Function that returns the left element of a record
      Put_Line("   return x[0]");
      New_Line;
      Put_Line("def Right(x):"); --Function that returns the right element of a record
      Put_Line("   return x[1]");
      New_Line;
      Put_Line("def Safety_Property(x):"); --Aux function defined in road_traffic.ads
      Put_Line("   return And( [ Or( x[Left(elem)] == ""Red"", x[Right(elem)] == ""Red"" ) for elem in Conflicts ] )");
      New_Line;
   end Print_Road_Traffic_Support;


   --Procedure that prints the support functions needed in python for testing arrays
   procedure Print_Array_Support is
   begin
      Put_Line("#---Array support functions");
      Put_Line("Array_Size = " & Array_Size'Image);
      Put_Line("variables = ['v%d' % i for i in range(Array_Size)]"); --This variables will simulate an array, and will be treated as a whole
      New_Line;
      Put_Line("def Last(x):"); --Function that returns the last index of an array in python
      Put_Line("   return len(x)-1");
      New_Line;
      Put_Line("def Range(x):"); --Function that returns the range of an array in python
      Put_Line("   return range(0, len(x))");
      New_Line;
   end Print_Array_Support;


   --Procedure that prints the support for the random test
   procedure Print_Random_Support is
   begin
      Put_Line("#---Random support function");
      Put_Line("import random");
      Put_Line("random.seed("& Random_Seed'Image &")  #Seed for random");
      New_Line;

      --Function that returns random values for a test vector according to the list of param type treatment
      Put_Line("def Random_Test_Vector():");
      Put_Line("   random_test_vector = []");
      New_Line;
      --We need to consider possible implicit type constraints at least,
      --otherwise tests could not even compile due to Ada strongly-typed nature
      for index in Params_Type_Treatment.First_Index .. Params_Type_Treatment.Last_Index loop
         --Random Integer
         if Params_Type_Treatment(index) = "Int" then
            if Implicit_Constraint_Map.Contains( Param_Types.Element(index) & "_range_left" ) then  --It has implicit constraints to consider
               Put_Line("   random_test_vector.append( random.randint("& Implicit_Constraint_Map( Param_Types(index) & "_range_left" ) &
                          ","& Implicit_Constraint_Map( Param_Types(index) & "_range_right" ) &") )");
            else  --No implicit constraints associated
               Put_Line("   random_test_vector.append( random.randint("& MinInt'Image & ","& MaxInt'Image &") )");
            end if;
         end if;
         --Random Float
         if Params_Type_Treatment(index) = "Real" then
            if Implicit_Constraint_Map.Contains( Param_Types.Element(index) & "_range_left" ) then  --It has implicit constraints to consider
               Put_Line("   random_test_vector.append( round( random.uniform("& Implicit_Constraint_Map( Param_Types(index) & "_range_left" ) &
                          ","& Implicit_Constraint_Map( Param_Types(index) & "_range_right" ) &"), 2 ) )");  --Includes rounding up to 2 decimals
            else  --No implicit constraints associated, we pick a random float between 0 and 1
               Put_Line("   random_test_vector.append( round( random.random(), 2 ) )"); --Includes rounding up to 2 decimals
            end if;
         end if;
         --Random Int Array
         if Params_Type_Treatment(index) = "Array" then
            Put_Line("   random_test_vector.append( list( random.sample( range("& MinInt'Image &","& MaxInt'Image &"), Array_Size ) ) )");
         end if;
         --Random Enumerate
         if Params_Type_Treatment(index) = "Enumerate" then
            Put_Line("   random_test_vector.append( random.choice("& Map_Keys.First_Element &") )");
         end if;
         --Random String Map
         if Params_Type_Treatment(index) = "Map" then
            Put_Line("   random_test_vector.append( [ random.choice("& Map_Values.First_Element &") for i in range(len("& Map_Keys.First_Element &"))] )");
         end if;
      end loop;
      New_Line;
      if Params_Type_Treatment.Length > 1 then
         Put_Line("   return tuple(random_test_vector)");
      else
         Put_Line("   return random_test_vector[0]");
      end if;
      New_Line;

      --Function that returns a random expected output regarding the returning type treatment
      Put_Line("def Random_Expected_Output():");
      --We need to consider possible implicit type constraints at least,
      --otherwise tests could not even compile due to Ada strongly-typed nature
      --Random Integer
      if Return_Type_Treatment.First_Element = "Int" then
         if Implicit_Constraint_Map.Contains( Return_Type.First_Element & "_range_left" ) then  --It has implicit constraints to consider
            Put_Line("   return random.randint("& Implicit_Constraint_Map( Return_Type.First_Element & "_range_left" ) &
                       ","& Implicit_Constraint_Map( Return_Type.First_Element & "_range_right" ) &") ");
         else  --No implicit constraints associated
            Put_Line("   return random.randint("& MinInt'Image & ","& MaxInt'Image &")");
         end if;
      end if;
      --Random Boolean
      if Return_Type_Treatment.First_Element = "Bool" then
         Put_Line("   return random.choice([True, False]) ");
      end if;
      --If target function is actually a procedure and returns nothing...
      if Return_Type_Treatment.First_Element = "none" then
         Put_Line("   return ""none"" ");
      end if;
      New_Line;

   end Print_Random_Support;


end Z3py_Printer;
