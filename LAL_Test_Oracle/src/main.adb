with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Langkit_Support.Slocs;
with Langkit_Support.Text;
with Libadalang.Analysis;
with Libadalang.Common;

with Config; use Config;                   --Configuration
with Node_Processing; Use Node_Processing; --Node processing functionality
with Z3py_Printer; Use Z3py_Printer;       --Printer of the Z3py program

procedure Main is
   package LAL renames Libadalang.Analysis;
   package LALCO renames Libadalang.Common;
   package Slocs renames Langkit_Support.Slocs;
   package Text renames Langkit_Support.Text;

   ------------------
   -- Process_Tree --
   ------------------

   Context : constant LAL.Analysis_Context := LAL.Create_Context;
begin
   -- The program needs a specification file, the name of the target function and the max number of solutions to generate
   --E.g: PriceVariable.ads AcceptOffer 1
   pragma Assert(Ada.Command_Line.Argument_Count = 3 or Ada.Command_Line.Argument_Count = 4);
   declare
      Filename : constant String := Ada.Command_Line.Argument (1);
      --Needs the path to the spec file, it depends on where you call this function from, of course.
      --If we will use it through a script, then the path might well be "./Case_Studies/filename"
      --However, if we execute it from the LAL_Test_Oracle directory, the path might well be "../Case_Studies/filename"
      Unit     : constant LAL.Analysis_Unit :=
        Context.Get_From_File ("./Case_Studies/" & Filename);
      Target_Function_Root : LAL.Ada_Node;   --Node with the subtree correspondant to the target function
      Handle_IsolatedInfo : Ada.Text_IO.File_Type;    --In order to redirect the program isolated info output to a file
      Handle_Z3_Printer   : Ada.Text_IO.File_Type;    --In order to redirect the program Z3py_Printer output to a file
   begin
      Put_Line ("== " & Filename & " ==");

      --  Report parsing errors, if any
      if Unit.Has_Diagnostics then
         for D of Unit.Diagnostics loop
            Put_Line (Unit.Format_GNU_Diagnostic (D));
         end loop;

      --  Otherwise, look for object, type, parameter declarations, function declaration, contract_cases of the target function, etc
      else
         --  Unit.Print; --Prints the whole tree

         --First, we fic the random seed if the user passed it as an argument
         if Ada.Command_Line.Argument_Count = 4 then
            --The last argument will be treated as the seed
            Random_Seed := Integer'Value( Ada.Command_Line.Argument (4) );
         end if;

         --Sets the target function name for the processor, note that in order to ease dynamic Strings I use a String_Vector
         --which contains just one element
         Set_Target_Function_Name_Processor( Ada.Command_Line.Argument (2) );

         --Sets the max number of solutions to generate
         max_solutions := Integer'Value( Ada.Command_Line.Argument (3) );

         if Verbose = True then
            Put_Line("Gathering information and constraints from " & Filename &
                    ", target function: " & Target_Function_Name.First_Element & "...");
         end if;

         Ada.Text_IO.Create (Handle_IsolatedInfo, Ada.Text_IO.Out_File, Target_Function_Name.First_Element & "-IsolatedInfo.txt");
         Ada.Text_IO.Set_Output (Handle_IsolatedInfo);

         Put_Line ("== " & Filename & " ==");

         Put_Line("--------- Types -------------");
         Unit.Root.Traverse (Process_Types'Access);       --Processing of types
         At_Least_One_Node_Processed;
         New_Line;

         Put_Line("--------- SubTypes -------------");
         Unit.Root.Traverse (Process_Subtypes'Access);    --Processing of subtypes
         At_Least_One_Node_Processed;
         New_Line;

         Put_Line("--------- Objects -------------");
         Unit.Root.Traverse (Process_Objects'Access);     --Processing of objects
         At_Least_One_Node_Processed;
         New_Line;

         Put_Line("--------- Declaration of the target function -------------");
         Unit.Root.Traverse (Process_Declaration'Access);  --Processing of the declaration of the target function
         pragma Assert( Nodes_Processed = True,
                     "ERROR: Target function """ & Target_Function_Name.First_Element & """ doesn't exist" );   --Target function must exists
         At_Least_One_Node_Processed;
         Target_Function_Root := Get_Target_Function_Root; --Reads the target function root node from the processor
         New_Line;

         -- Note that the search continues from the node of the function
         Put_Line("--------- Parameters of the target function -------------");
         Target_Function_Root.Traverse (Process_Parameters'Access);   --Processing of parameters of the target function
         Print_Params_Type_Treatment; --Used in Ada unit test integration
         At_Least_One_Node_Processed;
         New_Line;

         if not Random_Test then --Random testing doesn't require any constraint gathering
            Put_Line("--------- Global Preconditions of the target function -------------");
            Target_Function_Root.Traverse (Process_Preconditions'Access);  --Processing of the global preconditions of the target function
            At_Least_One_Node_Processed;
            New_Line;

            Put_Line("--------- Contract_Cases of the target function -------------");
            Target_Function_Root.Traverse (Process_Contracts'Access);    --Processing of the target function contract cases
            At_Least_One_Node_Processed;
            New_Line;

            Put_Line("--------- Global Postconditions of the target function -------------");
            Target_Function_Root.Traverse (Process_Postconditions'Access);    --Processing of the global postconditions of the target function
            At_Least_One_Node_Processed;
         end if;

         Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output); --Close the redirection

         if Verbose = True then
            Put_Line("Done");
         end if;

         --**********************************************************************************************************************
         --Once the SPARK code has been processed, we print the Z3py Test Oracle
         if Verbose = True then
            Put_Line("Afterwards, we proceed to generate the test oracle...");
         end if;

         Ada.Text_IO.Create (Handle_Z3_Printer, Ada.Text_IO.Out_File, Target_Function_Name.First_Element & "-Test_Oracle.py");
         Ada.Text_IO.Set_Output (Handle_Z3_Printer);

         Print_Header;                   --Header of the file
         Print_Objects;                  --Objects
         if not Random_Test then
            Print_Model_Variables;          --Model Variables
            Print_Solver;                   --Z3 Solver
            Print_Implicit_Constraints;     --Implicit constraints
            Print_Precondition;             --Explicit global precondition
            if not Contract_Cases_Z3.Is_Empty then
               for E of Contract_Cases_Z3 loop --Solves the constraints
                  Print_Contract_Case_Guard;   --Local precondition
                  Print_Model;
               end loop;
            else
               Print_Model;
            end if;
         else --Random Testing
            Print_Random_Test;
         end if;
         if Test_Negate_Precondition then
            Print_Negate_Precondition_Model; --Forces the oracle to create a default test vector that should fail
         end if;

         Ada.Text_IO.Set_Output (Ada.Text_IO.Standard_Output); --Close the redirection

         if Verbose = True then
            Put_Line("Done");
         end if;
      end if;
   end;

end Main;
