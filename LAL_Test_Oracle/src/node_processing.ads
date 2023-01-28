with Langkit_Support.Slocs;
with Langkit_Support.Text;
with Libadalang.Analysis;
with Libadalang.Common;
with Ada.Containers.Indefinite_Vectors;

with Config; use Config; --Configuration package

package Node_Processing is
   package LAL renames Libadalang.Analysis;
   package LALCO renames Libadalang.Common;
   package Slocs renames Langkit_Support.Slocs;
   package Text renames Langkit_Support.Text;

   --Procedure that sets the target function name
   procedure Set_Target_Function_Name_Processor ( Name : String );

   --Ada_Node with the root node of the target function
   Function_Root_Node : LAL.Ada_Node;

   --Procedure that returns the target_function_root class
   function Get_Target_Function_Root return LAL.Ada_Node;

   ---------------String management--------------------------

   --Procedure in charge of printing the content of a String vector
   procedure Print_String_Vector ( Info : String_Vector.Vector );

   --Vector of String with the name of the target function (contained in the first element)
   Target_Function_Name : String_Vector.Vector;

   ---------------Libadalang Type management--------------------------

   --Map for implicit constraints regarding Integers or Floats.
   --Example: type Price is delta 0.01 range 0.01 .. 99999.99, would be translated into the following 3 constraints:
   -- 1) <future_variable_name>/(1/delta_value) = x (x is Integer)   : Price_delta
   -- 2) <future_variable_name> >= range_left_value  : Price_range_left
   -- 3) <future_variable_name> <= range_right_value : Price_range_right
   Implicit_Constraint_Map : String_Hashed_Maps.Map;

   Type_Translation_Map : String_Hashed_Maps.Map; --Map with Ada type translations for the parameters types. E.g: Price => OrdinaryFixedPointDef

   --Vector of String with the treatment asssociated to each type. Necessary to properly read the future raw tests results.
   Params_Type_Treatment : String_Vector.Vector;

   --Function in charge of printing the Params_Type_Treatment vector
   procedure Print_Params_Type_Treatment;

   --Vector of String with the returning type treatment.
   Return_Type_Treatment : String_Vector.Vector;

   --***********************Function in charge of identifying unambiguous postconditions****
   function Unambiguous_Postcondition (Node : LAL.Expr) return Boolean;

   type PostCondition_Type is (Value, Behaviour);  --Value => unambiguous, behaviour => ambiguous

   type PostCondition is record
      Condition_Type : PostCondition_Type; --Value or Behaviour
      Condition : String_Vector.Vector;    --Condition text, must be a vector to deal with dynamic assigment
                                           --It will always contain just one String
   end record;

   package PostCondition_Vector is new Ada.Containers.Indefinite_Vectors --Postconditions Vector
       (Index_Type => Natural,
        Element_Type => PostCondition);


   --***********************Z3 support variables and functions******************

   --Vector of String with the Object declarations for Z3py
   Obj_Z3 : String_Vector.Vector;

   --Vector of String with the Variables for the Model (parameters). E.g: amount = Int('amount')
   Params_Z3 : String_Vector.Vector;

   --Vector of Strings with the names (isolated) of the variables in Ada
   Param_Names : String_Vector.Vector;

   --Vector of Strings with the types (isolated) of the variables in Ada
   Param_Types : String_Vector.Vector;

   --Vector of Strings with the type (isolated) of the returning value in Ada
   Return_Type : String_Vector.Vector;

   --Map of String with the main core of the definition of future parameters regarding type translation to Z3py. E.g: Price => Real, Val => Int
   Z3_Type_Translation_Map : String_Hashed_Maps.Map;

   --Vector of String with the implicit constraints to add to the model in Z3py
   Implicit_Constraint_Z3 : String_Vector.Vector;

   --String with the auxiliar variable 'x' integer needed for the 'delta' constraint
   Delta_Param_Z3 : String_Vector.Vector;

   --String with the explicit constraints (Precondition) to add to the model in Z3py
   Explicit_Constraint_Z3 : String_Vector.Vector;

   --Postcondition (record) with the global postcondition to consider in Z3py
   Global_Postcondition_Z3 : PostCondition;

   --Vector of String with the cases of the contract
   Contract_Cases_Z3 : String_Vector.Vector;

   --Vector of String with the guards of the Contract_Cases (Local Preconditions)
   Contract_Cases_Guards_Z3 : String_Vector.Vector;

   --Vector of Postconditions (type record) with the consequences of the Contract_Cases (Local Postconditions)
   Contract_Cases_Consequences_Z3 : PostCondition_Vector.Vector;

   --***********Auxiliar variables for node processing**************************

   --Variable that checks whether at least one node was processed or not
   Nodes_Processed : Boolean := False;

   procedure At_Least_One_Node_Processed; --Auxiliar function


   ----------------------------------------Functions in charge of logical expressions translation

   -------Function in charge of translating logical expressions
   function Translate_Logical_Expr (Node : LAL.Expr) return String;

   -------Function in charge of translating relational logical expressions
   function Translate_RelationOp (Node : LAL.Relation_Op) return String;

   -------Function in charge of translating attribute references inside logical expressions
   function Translate_AttributeRef (Node : LAL.Attribute_Ref) return String;

   -------Function in charge of translating binary logical expressions
   function Translate_BinOp (Node : LAL.Bin_Op) return String;

   -------Function in charge of translating unary logical expressions
   function Translate_UnOp (Node : LAL.Un_Op) return String;

   -------Function in charge of translating function call expressions
   function Translate_CallExpr (Node : LAL.Call_Expr) return String;

   -------Function in charge of translating symbolic indexing in function call expressions
   function Translate_SymbolicIndexing ( Call_Expr_Name : String; Operator : String; Right_Part : String ) return String;

   -------Function in charge of translating if-then-else logical expressions
   function Translate_IfExpr(Node : LAL.If_Expr) return String;

   -------Function in charge of translating the "others" logical condition
   function Translate_Others return String;

   -------Function in charge of translating quantified expressions expressions
   function Translate_QuantifiedExpr (Node : LAL.Quantified_Expr) return String;


   ----------------------------------------Functions in charge of processing different program parts

   ------Function that processes types and creates the correspondent implicit constraints
   function Process_Types (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

   ------Function that processes subtypes and creates the correspondent implicit constraints
   function Process_Subtypes (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

   ------Function that processes objects
   function Process_Objects (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

   -------Function that processes Parameters
   function Process_Parameters (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

   ------Function that processes the declaration of target function
   function Process_Declaration (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

   -------Function that processes Global Preconditions in the specification
   function Process_Preconditions (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

   -------Function that processes Contract_Cases in the specification of the target function
   function Process_Contracts (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

   -------Function that processes Global Postconditions in the specification
   function Process_Postconditions (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status;

end Node_Processing;
