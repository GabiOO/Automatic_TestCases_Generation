--This package contains all the configuration info needed
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;

package Config is

   --To replicate Z3 model results
   Z3_Random_Seed : constant Integer := 0;

   --Max solutions to generate. If set as 1, implements base case test generation
   max_solutions : Integer := -1;

   --String management
   package String_Vector is new Ada.Containers.Indefinite_Vectors --String Vector
       (Index_Type => Natural,
        Element_Type => String);

   package String_Hashed_Maps is new Ada.Containers.Indefinite_Hashed_Maps --String Map
   (Key_Type => String,
    Element_Type => String,
    Hash => Ada.Strings.Hash,
    Equivalent_Keys => "=");

   --********Variables associated to different support necessities**************
   --Integer support for python that ensures MaxInt = 2**31-1 and MinInt = -2**31
   Int_Support : Boolean := False;
   MaxInt : constant Integer := (2**31 - 1);
   MinInt : constant Integer := -2**31;

   --Number of digits desired, used in the 'digits' constraint
   Num_Digits : Integer;

   --Variable that checks whether Array support is needed
   Array_Support_Needed : Boolean := False;

   --If the program detects an array type, here will be stored the proper size
   Array_Size : Integer := -1;

   --Variable that checks whether Map support is needed
   Map_Support_Needed : Boolean := False;

   --If the program detects a map type, here will be stored the keys
   Map_Keys : String_Vector.Vector;

   --If the program detects a map type, here will be stored the values
   Map_Values : String_Vector.Vector;

   --Variable that checks if symbollic indexing is needed for the following expression translation
   Symbolic_Indexing : Boolean := False;
   Symbolic_Index : String_Vector.Vector; --Associated Symbolic Index to use in the translation

   --*************Boundary Analysis variables***********************************
   --Variable that checks wheter the user wants boundary analysis or not
   Boundary_Analysis : constant Boolean := False;

   --Variable that fixes the error permitted in boundary analysis
   Epsilon : constant Float := 0.1;

   --*************Tests that negate the explicit precondition*******************
   Test_Negate_Precondition : constant Boolean := False;

   --************Random Test****************************************************
   Random_Test : constant Boolean := False;
   Random_Seed : Integer := 0; --Seed for the random module in python

   --*******Verbose*****************
   Verbose : constant Boolean := False;

end Config;
