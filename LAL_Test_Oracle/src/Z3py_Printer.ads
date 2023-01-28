with Config; use Config;
with Node_Processing; Use Node_Processing;

package Z3py_Printer is

   --Number of the actual case (used in contract cases)
   actual_case : Natural := 0;

   --Postcondition_Type of the actual contract case or global postcondition
   --This value changes when we print a contract case consequence or a global postcondition
   Actual_Postcondition_Type : PostCondition_Type;

   --Procedure that prints the header for the program (author, z3 import, etc)
   procedure Print_Header;

   --Procedure that prints the general variables (Objects in SPARK)
   procedure Print_Objects;

   --Procedure that prints the model variables (Parameters of the target function in SPARK)
   procedure Print_Model_Variables;

   --Procedure that creates the Z3 solver
   procedure Print_Solver;

   --Procedure that prints the implicit constraints for the model variables
   procedure Print_Implicit_Constraints;

   --Procedure that prints the explicit constraints (Global Precondition)
   procedure Print_Precondition;

   --Procedure that prints the local precondition associated to the contract case
   procedure Print_Contract_Case_Guard;

   --Procedure that prints the contract case consequence (local postcodition) associated to the actual case
   procedure Print_Contract_Case_Consequence;

   --Procedure that prints the Postcondition (Global Postcondition) defining the expected value
   procedure Print_Postcondition;

   --Procedure that prints the test vector for Z3
   procedure Print_Test_Vector;

   --Procedure that ensures different solutions for the next iteration of the Z3 model
   procedure Print_Ensure_Different_Solutions;

   --Procedure that prints the generation of the model and main body of the program
   procedure Print_Model;

   --Procedure that prints a model that creates a default test vector negating the explicit pre of the target function
   procedure Print_Negate_Precondition_Model;

   --Procedure that prints a random test
   procedure Print_Random_Test;

   ----------------Support functions for python--------------------------
   --Procedure that prints the support for Integers boundaries
   procedure Print_Int_Support;

   --Procedure that prints the support functions needed in python for testing simple_trajectory.ads
   procedure Print_Trajectory_Support;

   --Procedure that prints the support for road_traffic.ads functions
   procedure Print_Road_Traffic_Support;

   --Procedure that prints the support functions needed in python for testing arrays
   procedure Print_Array_Support;

   --Procedure that prints the support for the random test
   procedure Print_Random_Support;

end Z3py_Printer;
