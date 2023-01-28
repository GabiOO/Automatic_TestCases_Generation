with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;

package body Node_Processing is

   --Procedure that sets the target function name
   procedure Set_Target_Function_Name_Processor ( Name : String ) is
   begin
      Target_Function_Name.Append( Name );
   end Set_Target_Function_Name_Processor;

   procedure Print_String_Vector ( Info : String_Vector.Vector ) is
   begin
      for E of Info loop
         Put_Line(E);
      end loop;
   end Print_String_Vector;


   --Procedure that returns the target_function_root class
   function Get_Target_Function_Root return LAL.Ada_Node is
   begin
      return Function_Root_Node;
   end Get_Target_Function_Root;


   procedure At_Least_One_Node_Processed is --Checks if at least one node was processed
   begin
      if Nodes_Processed = False then  --If nothing was processed
         Put_Line("None");
      else
         Nodes_Processed := False; --Reset
      end if;
   end At_Least_One_Node_Processed;

   ------Function that processes types
   function Process_Types (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin
      if Node.Kind = LALCO.Ada_Type_Decl then
         Put_Line
           ("Line"
            & Slocs.Line_Number'Image (Node.Sloc_Range.Start_Line)
            & ": " & Text.Image( Node.Text ));
         Nodes_Processed := True;
         declare
            Type_Decl : constant LAL.Type_Decl := Node.As_Type_Decl;            --Type declaration
            Type_Name : constant String := Text.Image( Type_Decl.F_Name.Text ); --Type name
            Type_Kind : constant String := Type_Decl.F_Type_Def.Kind_Name;      --Kind
         begin
            Put_Line ("   Name: " & Type_Name );
            Put_Line ("   Kind: " & Type_Kind );

            --Is it an Ordinary_Fixed_Point_Definition? (delta-range combination)
            if Type_Kind = "OrdinaryFixedPointDef" then
               Type_Translation_Map.Include( Type_Name, "OrdinaryFixedPointDef" ); --Association in between the type name and "OrdinaryFixedPointDef"
               Z3_Type_Translation_Map.Include ( Type_Name, "Real");               --Type translated to Real in Z3py
               declare
                  FixedPoint_Def : constant LAL.Ordinary_Fixed_Point_Def :=
                    Type_Decl.F_Type_Def.As_Ordinary_Fixed_Point_Def;
               begin
                  Put_Line ("   Delta: " & Text.Image( FixedPoint_Def.F_Delta.Text ));
                  Put_Line ("   Range: " & Text.Image( FixedPoint_Def.F_Range.Text ));
                  --We add implicit constraints regarding delta/range in type declaration
                  --Note that the constraints are not complete since we don't know the name of
                  --the parameters involved. Therefore, once we know them we simply add "<param_name>"
                  --at the beginning of the consrtaint string in order to complete it
                  --Delta constraint creation
                  Implicit_Constraint_Map.Include ( Type_Name & "_delta", "*(1/" & Text.Image( FixedPoint_Def.F_Delta.Text ) & ") == aux" );
                  --Since the previous constraint requires an auxiliar Integer variable, we add it to Z3
                  Delta_Param_Z3.Append( "aux = Int('aux')" );
                  --Range constraints creation
                  Implicit_Constraint_Map.Include ( Type_Name & "_range_left",
                     Text.Image( FixedPoint_Def.F_Range.F_Range.As_Bin_Op.F_Left.Text ) );  --Range Left bound
                  Implicit_Constraint_Map.Include ( Type_Name & "_range_right",
                     Text.Image( FixedPoint_Def.F_Range.F_Range.As_Bin_Op.F_Right.Text ) ); --Range Right bound
                  end;
            end if;

            --Is it a Floating_Point_Definition? (constraint using "digits")
            if Type_Kind = "FloatingPointDef" then
               Type_Translation_Map.Include( Type_Name, "FloatingPointDef" );   --Ada type association
               Z3_Type_Translation_Map.Include ( Type_Name, "Real");            --Type translated to Real in Z3py
               --Later on, in C++, the decimals will be fixed for integrating the test cases in Ada
               Num_Digits := Integer'Value( Text.Image( Type_Decl.F_Type_Def.As_Floating_Point_Def.F_Num_Digits.Text ) ); --Digits desired
            end if;

            --Is it a ranged Integer, Signed_Int_TypeDef? (constraint using range)
            if Type_Kind = "SignedIntTypeDef" then
                  Type_Translation_Map.Include( Type_Name, "SignedIntTypeDef" );  --Ada type association
                  Z3_Type_Translation_Map.Include ( Type_Name, "Int");            --Type translated to Int in Z3py
               declare
                  Range_Spec : constant LAL.Range_Spec := Node.As_Type_Decl.F_Type_Def.As_Signed_Int_Type_Def.F_Range.As_Range_Spec;
               begin
                  Put_Line ("   Range: " & Text.Image( Range_Spec.Text ));
                  --We add implicit constraints related to this type range
                  Implicit_Constraint_Map.Include ( Type_Name & "_range_left",
                      Text.Image( Range_Spec.F_Range.As_Bin_Op.F_Left.Text ) );  --Range Left bound
                  Implicit_Constraint_Map.Include ( Type_Name & "_range_right",
                      Text.Image( Range_Spec.F_Range.As_Bin_Op.F_Right.Text ) ); --Range Right bound
               end;
            end if;

            --Is it an array?
            if Type_Kind = "ArrayTypeDef" then
               --We only process constrained arrays
               if( Type_Decl.F_Type_Def.As_Array_Type_Def.F_Indices.Kind_Name = "ConstrainedArrayIndices" ) then
                  --Note that arrays will have a special treatment in Z3
                  Type_Translation_Map.Include( Type_Name, "ArrayTypeDef" );
                  declare
                     Constraint_List : constant LAL.Constraint_List :=
                       Type_Decl.F_Type_Def.As_Array_Type_Def.F_Indices.As_Constrained_Array_Indices.F_List.As_Constraint_List;
                  begin
                     for Elem of Constraint_List loop --It has to contain just one element and it must be a: integer explicit range X .. Y, or an Enumerate
                        if ( Elem.Kind_Name = "BinOp" and then Text.Image(Elem.As_Bin_Op.F_Op.Text) = ".." ) then --Normal (integer) array
                           Z3_Type_Translation_Map.Include( Type_Name, "Array" );
                           --Array Range
                           Put_Line ("   Array_Range: " & Text.Image( Elem.Text ));
                           --Size = 1 + Right bound - Left bound. E.g: range 1 .. 10 => 1 + 10 - 1 = 10
                           Array_Size := 1 + Integer'Value( Text.Image( Elem.As_Bin_Op.F_Right.Text ) ) --Right Bound
                             -  --Minus
                             Integer'Value( Text.Image( Elem.As_Bin_Op.F_Left.Text ) ); --Left Bound
                        elsif ( Elem.Kind_Name = "SubtypeIndication"
                               and then Type_Translation_Map( Text.Image(Elem.As_Subtype_Indication.F_Name.Text) ) = "EnumTypeDef" ) then --This array must be treated as a map
                           Z3_Type_Translation_Map.Include( Type_Name, "Map" );
                           --Map keys and values
                           Put_Line("   Map_Keys: " & Text.Image( Elem.Text ));
                           Map_Keys.Append( Text.Image( Elem.Text ) );
                           Put_Line("   Map_Values: " & Text.Image( Type_Decl.F_Type_Def.As_Array_Type_Def.F_Component_Type.Text ));
                           Map_Values.Append( Text.Image( Type_Decl.F_Type_Def.As_Array_Type_Def.F_Component_Type.Text ) );
                        else
                           Put_Line("Sorry but array ranges must be explicit integer ranges or Enumerates.");
                        end if;
                     end loop;
                  end;
               end if;
            end if;

            --Is it an enumerate?
            if Type_Kind = "EnumTypeDef" then
               --Enumerates will be treated as python string arrays. E.g: Path = ("North","South",...)
               Type_Translation_Map.Include( Type_Name, "EnumTypeDef" );
               Z3_Type_Translation_Map.Include( Type_Name, "Enumerate" );
               declare
                  Enum_List : constant LAL.Enum_Literal_Decl_List :=
                    Type_Decl.F_Type_Def.As_Enum_Type_Def.F_Enum_Literals;
                  Enum_Elements : String_Vector.Vector;
                  Z3_Python_Array : String_Vector.Vector; --The last element of this vector will contain the array for python
                  index : Integer := 0; --Using an index avoids cursor tampering
               begin
                  for Elem of Enum_List loop --First, we store all the elements as strings, and we add then individually as string objects
                     Enum_Elements.Append( Text.Image( Elem.F_Name.Text ) );
                     Obj_Z3.Append( Text.Image( Elem.F_Name.Text ) & " = """ & Text.Image( Elem.F_Name.Text ) & """" );
                  end loop;
                  Z3_Python_Array.Append( "(" ); --Then we create the python array
                  for Elem of Enum_Elements loop
                     declare
                        String_To_Add : constant String := Z3_Python_Array( index ); --To avoid Cursor tampering
                     begin
                        if Elem /= Enum_Elements.Last_Element then
                           Z3_Python_Array.Append( String_To_Add & Elem & "," );
                        else
                           Z3_Python_Array.Append( String_To_Add & Elem & ")" );
                        end if;
                        index := index + 1;
                     end;
                  end loop;
                  --Finally, we add the array of enum elements to the Z3 model objects
                  Obj_Z3.Append( Type_Name & " = " & Z3_Python_Array.Last_Element );
               end;
            end if;

         end;
      end if;

      return LALCO.Into;
   end Process_Types;


   ------Function that processes subtypes and creates the correspondent implicit constraints
   function Process_Subtypes (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin
      if Node.Kind = LALCO.Ada_Subtype_Decl then
         Put_Line
           ("Line"
            & Slocs.Line_Number'Image (Node.Sloc_Range.Start_Line)
            & ": " & Text.Image( Node.Text ));
         Nodes_Processed := True;
         declare
            Subtype_Name : constant String := Text.Image( Node.As_Subtype_Decl.F_Name.Text ); --Subtype name
            Subtype_Decl : constant LAL.Subtype_Decl := Node.As_Subtype_Decl;                 --Subtype declaration
            Upper_Type : constant String := Text.Image( Subtype_Decl.F_Subtype.F_Name.Text ); --Type derived for this subtype
         begin
            Put_Line ("   Name: " & Subtype_Name );
            Put_Line ("   Upper Type: " & Upper_Type );
            --It must be a subrange integer or a previously processed type
            Assert( Upper_Type = "Integer" or Type_Translation_Map.Contains( Upper_Type ), "This subtype is not supported yet");
            declare
                  Range_Spec : constant LAL.Range_Spec := Node.As_Subtype_Decl.F_Subtype.F_Constraint.As_Range_Constraint.F_Range;
            begin
               if Upper_Type = "Integer" then
                  Z3_Type_Translation_Map.Include ( Subtype_Name, "Int"); --Type translated to Int in Z3py
                  Put_Line ("   Integer of Range: " & Text.Image( Range_Spec.Text ));
               else --It's upper type must have been processed before
                  declare
                     Upper_Type_Translation : constant String := Type_Translation_Map( Upper_Type ); --Upper type ada translation
                  begin
                     --Subtypes must have the same Ada Translation Type as their upper type
                     Type_Translation_Map.Include( Subtype_Name, Upper_Type_Translation );
                     --Now we check whether it's a subranged Integer or Float
                     if Upper_Type_Translation = "SignedIntTypeDef" then
                        Z3_Type_Translation_Map.Include ( Subtype_Name, "Int"); --Type translated to Int in Z3py
                        Put_Line ("   Integer of Range: " & Text.Image( Range_Spec.Text ));
                     elsif Upper_Type_Translation = "OrdinaryFixedPointDef" or
                       Type_Translation_Map( Upper_Type ) = "FloatingPointDef"
                     then
                        Z3_Type_Translation_Map.Include ( Subtype_Name, "Real"); --Type translated to Int in Z3py
                        Put_Line ("   Float of Range: " & Text.Image( Range_Spec.Text ));
                     end if;
                  end;
               end if;
               --Afterwards, we add implicit constraints related to this subtype (sub)range
                  Implicit_Constraint_Map.Include ( Subtype_Name & "_range_left",
                     Text.Image( Range_Spec.F_Range.As_Bin_Op.F_Left.Text ) );  --Range Left bound
                  Implicit_Constraint_Map.Include ( Subtype_Name & "_range_right",
                     Text.Image( Range_Spec.F_Range.As_Bin_Op.F_Right.Text ) ); --Range Right bound
            end;
         end;
      end if;

      return LALCO.Into;
   end Process_Subtypes;


   ------Function that processes objects
   function Process_Objects (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin
      if Node.Kind = LALCO.Ada_Object_Decl then --Object declaration
         Put_Line
           ("Line"
            & Slocs.Line_Number'Image (Node.Sloc_Range.Start_Line)
            & ": " & Text.Image( Node.Text ));
         Nodes_Processed := True;
         declare
            Object : constant LAL.Object_Decl := Node.As_Object_Decl;
            Type_Decl : constant LAL.Base_Type_Decl := Node.As_Object_Decl.F_Type_Expr.P_Designated_Type_Decl;
         begin
            Put_Line ("   Name: " & Text.Image( Object.F_Ids.Text ));
            Put_Line ("   Type: " & Text.Image( Type_Decl.Text ));
            Put_Line ("   Value: " & Text.Image( Object.F_Default_Expr.Text ));
            --We add the object for Z3
            Obj_Z3.Append(Text.Image( Object.F_Ids.Text ) & " = " & Translate_Logical_Expr( Object.F_Default_Expr) );
         end;

      elsif Node.Kind = LALCO.Ada_Number_Decl then --"Number" declaration, special type of objects
         Put_Line
           ("Line"
            & Slocs.Line_Number'Image (Node.Sloc_Range.Start_Line)
            & ": " & Text.Image( Node.Text ));
         Nodes_Processed := True;
         declare
            Number : constant LAL.Number_Decl := Node.As_Number_Decl;
         begin
            Put_Line ("   Name: " & Text.Image( Number.F_Ids.Text ));
            Put_Line ("   Type: Number");
            Put_Line ("   Value: " & Text.Image( Number.F_Expr.Text ));
            --We add the number for Z3
            Obj_Z3.Append(Text.Image( Number.F_Ids.Text ) & " = " & Translate_Logical_Expr( Number.F_Expr ) );
         end;
      end if;

      return LALCO.Into;
   end Process_Objects;


   ------Function that processes the declaration of target function
   function Process_Declaration (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin

      if Node.Kind = LALCO.Ada_Subp_Decl then
         declare
            Function_Name : constant String := Text.Image( Node.As_Subp_Decl.F_Subp_Spec.As_Subp_Spec.F_Subp_Name.Text );
         begin
            if Function_Name = Target_Function_Name.First_Element then
               Put_Line
                 ("Line"
                  & Slocs.Line_Number'Image (Node.Sloc_Range.Start_Line)
                  & ": " & Text.Image( Node.Text ));
               Put_Line("   Name: " & Function_Name);
               if Text.Image( Node.As_Subp_Decl.F_Subp_Spec.As_Subp_Spec.F_Subp_Kind.Text ) = "function" then
                  Return_Type.Append( Text.Image( Node.As_Subp_Decl.F_Subp_Spec.As_Subp_Spec.F_Subp_Returns.Text ) );
                  Put_Line("   Returns: " & Return_Type.First_Element );
                  --Returning Type Treatments
                  if Return_Type.First_Element = "Integer" then
                     Put_Line("   Treatment: Int" );
                     Return_Type_Treatment.Append( "Int" );
                  elsif Return_Type.First_Element = "Boolean" then
                     Put_Line("   Treatment: Bool" );
                     Return_Type_Treatment.Append( "Bool" );
                  else -- Special Type Treatment
                        Assert( Z3_Type_Translation_Map.Contains( Return_Type.First_Element ), "Parameter type not processed" );
                        Put_Line("   Treatment: " & Z3_Type_Translation_Map( Return_Type.First_Element ) );
                        Return_Type_Treatment.Append( Z3_Type_Translation_Map( Return_Type.First_Element ) );
                  end if;
               else --It is a procedure, not a function
                  Put_Line("   Returns: nothing" );
                  Put_Line("   Treatment: none" );
                  Return_Type.Append("none");
                  Return_Type_Treatment.Append( "none" );
               end if;
               Nodes_Processed := True;
               --The search of information and constraints will continue from this node
               Function_Root_Node := Node.As_Ada_Node;
            end if;
         end;
      end if;

      return LALCO.Into;
   end Process_Declaration;


   -------Function that processes Parameters
   function Process_Parameters (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin
      --Each parameter has a param_spec associated, except for param lists such as: X, Y : Integer,
      --In such cases both belong to a single param_spec common
      if Node.Kind = LALCO.Ada_Param_Spec then
         Put_Line
           ("Line"
            & Slocs.Line_Number'Image (Node.Sloc_Range.Start_Line)
            & ": " & Text.Image( Node.Text ));
         Nodes_Processed := True;
         declare
            Names : constant LAL.Defining_Name_List := Node.As_Param_Spec.F_Ids; --E.g: X, Y : Integer; Z : Float. It may contain one or more ids
            Param_Type : constant String := Text.Image( Node.As_Param_Spec.As_Base_Formal_Param_Decl.P_Formal_Type.F_Name.Text );
         begin
            for E of Names loop
               Put_Line ("   Name: " & Text.Image( E.Text ));
               Put_Line ("   Type: " & Param_Type);

               --Creates the Z3 model variable:
               Param_Names.Append( Text.Image( E.Text ) );
               Param_Types.Append( Param_Type );

               if Param_Type = "Integer" then
                  Int_Support := True; --Int boundaries support for python
                  Params_Type_Treatment.Append( "Int" );
                  Params_Z3.Append( Text.Image( E.Text ) & " = Int('" & Text.Image( E.Text ) & "')"); --E.g: x = Int('x')
                  --Note that python boundaries for Integers are bigger than Ada or C++ boundaries, so we must ensure them
                  Implicit_Constraint_Z3.Append( Text.Image( E.Text ) & " >= " & MinInt'Image );  --Range Left
                  Implicit_Constraint_Z3.Append( Text.Image( E.Text ) & " <= " & MaxInt'Image ); --Range Right

               elsif Param_Type = "Float" then
                  Params_Type_Treatment.Append( "Real" );
                  Params_Z3.Append( Text.Image( E.Text ) & " = Real('" & Text.Image( E.Text ) & "')"); --E.g: x = Real('x')

               --If type is not Integer or Float, then it has special conditions to consider...
               elsif Type_Translation_Map( Param_Type ) = "ArrayTypeDef" then
                  --Is it an array or a map?
                  if Z3_Type_Translation_Map( Param_Type ) = "Array" then
                     Params_Type_Treatment.Append( "Array" );
                     Array_Support_Needed := True; -- We need to include Array support in python

                     Params_Z3.Append( Text.Image( E.Text ) & " = [ Int(elem) for elem in variables ]" ); --'variables' is defined in the array support
                     --Since it's an Integer Array, we have to make sure every element is in between the Integer boundaies fixed
                     Implicit_Constraint_Z3.Append( "And( [ elem >= " & MinInt'Image & " for elem in " & Text.Image( E.Text ) & " ] )");  --Range Left
                     Implicit_Constraint_Z3.Append( "And( [ elem <= " & MaxInt'Image & " for elem in " & Text.Image( E.Text ) & " ] )");  --Range Right
                  else --It's a map
                     Params_Type_Treatment.Append( "Map" );
                     Map_Support_Needed := True; -- We need to include Map support in python
                     Obj_Z3.Append( "values = [ String('value%i' % i) for i in range(len("& Map_Keys.First_Element &")) ]" ); --The values of the map will be the variables
                     Params_Z3.Append( Text.Image( E.Text ) & " = { key:value for (key,value) in zip("& Map_Keys.First_Element &",values) }" );
                     --We make sure the values belong to the proper enumerate associated
                     Implicit_Constraint_Z3.Append( "And( [ Or( [ value == "& Map_Values.First_Element &"[i] for i in range(len("& Map_Values.First_Element &")) ] ) for value in values ] )");
                  end if;

               elsif Type_Translation_Map( Param_Type ) = "EnumTypeDef" then
                  Params_Type_Treatment.Append( "Enumerate" );
                  Params_Z3.Append( Text.Image( E.Text ) & " = String('"& Text.Image( E.Text ) &"')" );
                  --We make sure the values belong to the proper enumerate associated
                  Implicit_Constraint_Z3.Append( "Or( [ "& Text.Image( E.Text ) &" == elem for elem in "& Param_Type &" ] )");

               else --It's a type derived from Integer or Float...
                  Assert( Z3_Type_Translation_Map.Contains( Param_Type ), "Parameter type not supported yet");

                  --First, we create the model variable considering the Z3 type translation previously done. E.g: amount = Real('amount')
                  Params_Type_Treatment.Append( Z3_Type_Translation_Map( Param_Type ) ); --Int or Real
                  Params_Z3.Append( Text.Image( E.Text ) & " = " & Z3_Type_Translation_Map( Param_Type ) & "('" & Text.Image( E.Text ) & "')");

                  --Next, we add the delta constraint if necessary
                  if Implicit_Constraint_Map.Contains( Param_Type & "_delta" ) then
                     Implicit_Constraint_Z3.Append( Text.Image( E.Text ) & Implicit_Constraint_Map( Param_Type & "_delta" ) ); --Delta constraint
                  end if;

                  --Finally, we deal with the range constraint if necessary
                  if Implicit_Constraint_Map.Contains( Param_Type & "_range_left" ) then
                     Implicit_Constraint_Z3.Append( Text.Image( E.Text ) & " >= " & Implicit_Constraint_Map( Param_Type & "_range_left") );  --Range Left
                     Implicit_Constraint_Z3.Append( Text.Image( E.Text ) & " <= " & Implicit_Constraint_Map( Param_Type & "_range_right") ); --Range Right
                  end if;
               end if;

               --If Boundary Analysis is desired, and there are range boundaries, we add extra conditions
               if Boundary_Analysis then
                  if Implicit_Constraint_Map.Contains( Param_Type & "_range_left") then --If it already has a special range
                     Implicit_Constraint_Z3.Append(
                        "Or( abs(" & Text.Image( E.Text ) & " - " & Implicit_Constraint_Map( Param_Type & "_range_left") & ") <= " & Epsilon'Image & ", "
                           & "abs(" & Text.Image( E.Text ) & " - " & Implicit_Constraint_Map( Param_Type & "_range_right") & ") <= " & Epsilon'Image & ")");
                  elsif Param_Type = "Integer" then --If it doesn't have a specific range but it is an Integer
                     Implicit_Constraint_Z3.Append(
                        "Or( abs(" & Text.Image( E.Text ) & " - MaxInt) <= " & Epsilon'Image & ", "
                           & "abs(" & Text.Image( E.Text ) & " - MinInt) <= " & Epsilon'Image & ")");
                  end if;
               end if;

            end loop;
         end;
      end if;

      return LALCO.Into;
   end Process_Parameters;


   --Function in charge of printing the Params_Type_Treatment vector
   procedure Print_Params_Type_Treatment is
   begin
      Put("Parameters Type Treatment: ");
      for index in Params_Type_Treatment.First_Index..Params_Type_Treatment.Last_Index loop
         Put( Params_Type_Treatment(index) );
         if index /= Params_Type_Treatment.Last_Index then
            Put( ", " );
         end if;
      end loop;
      New_Line;
   end Print_Params_Type_Treatment;


   -------Function that processes Global Preconditions in the specification
   function Process_Preconditions (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin
      if Node.Kind = LALCO.Ada_Aspect_Spec
      then
         declare
            --The aspect list contains pre, post, contract_cases, etc, but here we only focus on Pre
            Aspect_List : constant LAL.Aspect_Assoc_List := Node.As_Aspect_Spec.F_Aspect_Assocs;
         begin
            for Aspect of Aspect_List loop
               if Text.Image( Aspect.F_Id.Text ) = "Pre" then
                  Put_Line("Line"
                           & Slocs.Line_Number'Image (Aspect.Sloc_Range.Start_Line)
                           & ": " & Text.Image( Aspect.Text ));
                  -- We add the precondition to the Z3 printer
                  Explicit_Constraint_Z3.Append( Translate_Logical_Expr( Aspect.F_Expr ) );
                  Nodes_Processed := True;
               end if;
            end loop;
         end;
      end if;

      return LALCO.Into;
   end Process_Preconditions;


   -------Function in charge of translating logical expressions
   function Translate_Logical_Expr (Node : LAL.Expr) return String is
      Kind_Name : constant String := Node.Kind_Name;
   begin
      if Kind_Name = "RelationOp" then --The RelationOp acts as base case to stop recursion. E.g: x < 1
         return Translate_RelationOp( Node.As_Relation_Op );
      end if;
      if Kind_Name = "BinOp" then
         return Translate_BinOp( Node.As_Bin_Op );
      end if;
      if Kind_Name = "UnOp" then
         return Translate_UnOp( Node.As_Un_Op );
      end if;
      if Kind_Name = "ParenExpr" then
         return Translate_Logical_Expr( Node.As_Paren_Expr.F_expr );
      end if;
      if Kind_Name = "CallExpr" then --The CallExpr acts as base case to stop recursion as well. E.g: Length(Q)
         return Translate_CallExpr( Node.As_Call_Expr );
      end if;
      if Kind_Name = "IfExpr" then       --If-then-else expressions
         return Translate_IfExpr( Node.As_If_Expr );
      end if;
      if Kind_Name = "AttributeRef" then --E.g: Frame'Last
         return Translate_AttributeRef( Node.As_Attribute_Ref );
      end if;
      if Kind_Name = "DottedName" then   --E.g: Q.Capacity
         return Text.Image( Node.As_Dotted_Name.F_Suffix.Text ) & "(" & Text.Image( Node.As_Dotted_Name.F_Prefix.Text ) & ")";
      end if;
      if Kind_Name = "QuantifiedExpr" then
         return Translate_QuantifiedExpr( Node.As_Quantified_Expr );
      end if;

      --If none of the previous matched, it's treated as normal text
      return Text.Image( Node.Text );

   end Translate_Logical_Expr;


   -------Function in charge of translating relational logical expressions
   function Translate_RelationOp (Node : LAL.Relation_Op) return String is
      Left_Part : constant String := Translate_Logical_Expr( Node.F_Left );     --Left part of the relational expression
      Right_Part : constant String := Translate_Logical_Expr( Node.F_Right );   --Right part of the relational expression
      --Operator
      Operator_Text : constant String := (if Text.Image( Node.F_Op.Text ) = "=" then "=="     --Equality
                                          elsif Text.Image( Node.F_Op.Text ) = "/=" then "!=" --Negation
                                          else  Text.Image( Node.F_Op.Text ) );               --The rest (<, <=, >, >=)
   begin
      if not Symbolic_Indexing then --Normal Treatment
         return Left_Part & " " & Operator_Text & " " & Right_Part;
      else --Special treatment for expressions with symbolic indexing within call expressions
         return Translate_SymbolicIndexing( Left_Part, Operator_Text, Right_Part );
      end if;
   end Translate_RelationOp;


   -------Function in charge of translating attribute references inside logical expressions
   function Translate_AttributeRef (Node : LAL.Attribute_Ref) return String is
   begin
      if Node.F_Args.Is_Null then --Normal Treatment
         return Text.Image(Node.F_Attribute.Text) & "( " & Text.Image(Node.F_Prefix.Text) & ")";
      else
         return Text.Image(Node.F_Attribute.Text) & "( " & Text.Image(Node.F_Args.Text) & ")";
      end if;
   end Translate_AttributeRef;


   -------Function in charge of translating binary logical expressions
   function Translate_BinOp (Node : LAL.Bin_Op) return String is
      Left_Part : constant String := Translate_Logical_Expr( Node.F_Left );
      Right_Part : constant String := Translate_Logical_Expr( Node.F_Right );
      Op_Text : constant String := Text.Image( Node.F_Op.Text );
   begin
      --If it is an AND or AND THEN expression
      if Op_Text = "and" or Op_Text = "and then" then
         return "And( " & Left_Part & ", " & Right_Part & " )";
      end if;
      --If it is an OR expression
      if Op_Text = "or" then
         return "Or( " & Left_Part & ", " & Right_Part & " )";
      end if;
      --If it is an addition ("+") expression
      if Op_Text = "+" then
         return Left_Part & " + " & Right_Part;
      end if;
      --If it is an addition ("-") expression
      if Op_Text = "-" then
         return Left_Part & " - " & Right_Part;
      end if;
      --If it is a division ("/") expression
      if Op_Text = "/" then
         return Left_Part & " / " & Right_Part;
      end if;
      --If it refers to a range
      if Op_Text = ".." then
         --The plus 1 ensures a good translation, range in python doesn't reach the last element but in Ada it does
         return "range( " & Left_Part & ", " & Right_Part & "+1 )";
      end if;
      --Other binary operators
      return "Binary operator not supported yet";
   end Translate_BinOp;


   -------Function in charge of translating unary logical expressions
   function Translate_UnOp (Node : LAL.Un_Op) return String is
   begin
      --If it is a NOT expression
      if Text.Image( Node.F_Op.Text ) = "not" then
         return "Not( " & Translate_Logical_Expr( Node.F_Expr ) & " )";
      end if;
      --If it is a minus sign
      if Text.Image( Node.F_Op.Text ) = "-" then
         return "-" & Translate_Logical_Expr( Node.F_Expr );
      end if;
      --If it a plus sign
      if Text.Image( Node.F_Op.Text ) = "+" then
         return "+" & Translate_Logical_Expr( Node.F_Expr );
      end if;
      --Other unary operators
      return "Unary operator not Supported yet";
   end Translate_UnOp;


   -------Function in charge of translating function call expressions
   function Translate_CallExpr (Node : LAL.Call_Expr) return String is
      Call_Expr_Name : constant String := Text.Image(Node.F_Name.Text);
      Expr_Suffix : String_Vector.Vector;
      Index : String_Vector.Extended_Index;
   begin
      --First, we need to translate the suffix expression
      for Elem of Node.F_Suffix.As_Assoc_List loop --Node.F_Suffix returns an Assoc_List
         Expr_Suffix.Append( Translate_Logical_Expr( Elem.As_Param_Assoc.F_R_Expr ) );
      end loop;
      --Then, we check whether we are dealing with an array/mao access or a normal function call
      Index := Param_Names.Find_Index( Call_Expr_Name );
      --If the expression is an access to an array/map element, we need to translate A(x) into A[x] for python
      if Index /= String_Vector.No_Index then
         if Z3_Type_Translation_Map( Param_Types( Index ) ) = "Array"  then
            return Call_Expr_Name & "[" & Expr_Suffix.Last_Element & "]";
         else --The expression is an access to a map element, the element used to access is a symbolic index?
            Index := Param_Names.Find_Index( Expr_Suffix.Last_Element  );
            if Index = String_Vector.No_Index then --Normal indexing
               return Call_Expr_Name & "[" & Expr_Suffix.Last_Element  & "]";
            else --Symbolic indexing
               Symbolic_Indexing := True; --We activate the symbolic indexing translation
               Symbolic_Index.Append( Expr_Suffix.Last_Element  );
               return Call_Expr_Name;
            end if;
         end if;
      else --Normal function call. E.g: Length(Q)
         return Text.Image( Node.Text );
      end if;
   end Translate_CallExpr;


   -------Function in charge of translating symbolic indexing in function call expressions
   function Translate_SymbolicIndexing ( Call_Expr_Name : String; Operator : String; Right_Part : String ) return String is
   begin
      Symbolic_Indexing := False; --Reset
      return "And( [ If("& Symbolic_Index.Last_Element &" == key , "& Call_Expr_Name &
                 "[key] "& Operator &" "& Right_Part &", True) for key in "& Call_Expr_Name &".keys()] )";
   end Translate_SymbolicIndexing;


   -------Function in charge of translating if-then-else logical expressions
   function Translate_IfExpr(Node : LAL.If_Expr) return String is
      If_Condition : String := Translate_Logical_Expr( Node.F_Cond_Expr );
      Then_Condition : String := Translate_Logical_Expr( Node.F_Then_Expr );
   begin
      --In Z3, the structure is If(cond, then, else), note that having an else condition is mandatory.
      --If the Ada if-expression has no else, then else condition should be set as true for Z3
      if not Node.F_Else_Expr.Is_Null then
         return "If(" & If_Condition & ", " & Then_Condition & ", " & Translate_Logical_Expr( Node.F_Else_Expr ) & ")";
      else
        return "If(" & If_Condition & ", " & Then_Condition & ", True)";
      end if;
   end Translate_IfExpr;


   -------Function in charge of translating the "others" logical condition
   function Translate_Others return String is
      Others_Constraint : String_Vector.Vector;
      index : Natural := 0;
   begin
      --We simply add the negation of all the contract cases guards stored up to the moment
      Others_Constraint.Append("Not( ");
      for Guard of Contract_Cases_Guards_Z3 loop
         declare
            Contraint_To_Add : constant String := Others_Constraint( index ); --To avoid Cursor tampering
         begin
            if Guard /= Contract_Cases_Guards_Z3.Last_Element then
               Others_Constraint.Append( Contraint_To_Add & Guard & "), Not(");
            else
               Others_Constraint.Append( Contraint_To_Add & Guard & " )");
            end if;
         end;
         index := index + 1;
      end loop;

      return Others_Constraint.Last_Element; --Last element will gather all
   end Translate_Others;


   -------Function in charge of translating quantified expressions expressions
   function Translate_QuantifiedExpr (Node : LAL.Quantified_Expr) return String is
      Loop_Variable : constant String := Text.Image( Node.F_Loop_Spec.F_Var_Decl.Text );
      Loop_Iter_Expr : constant String := Translate_Logical_Expr( Node.F_Loop_Spec.F_Iter_Expr.As_Expr );
      Loop_Body_Expr : constant String := Translate_Logical_Expr( Node.F_Expr );
      Quantifier_Type : constant String := Text.Image( Node.F_Quantifier.Text );
   begin
      if Quantifier_Type = "all" then --It's a "for all" expression
         return "And( [ " & Loop_Body_Expr & " for " & Loop_Variable & " in " & Loop_Iter_Expr & "] )";
      elsif Quantifier_Type = "some" then --It's a "for some" expression
         return "Or( [ " & Loop_Body_Expr & " for " & Loop_Variable & " in " & Loop_Iter_Expr & "] )";
      else
         Put_Line("Quantifier type: " & Quantifier_Type);
         return "Quantifier not supported yet";
      end if;
   end Translate_QuantifiedExpr;


   ------Function in charge of identifying unambiguous postconsitions
   function Unambiguous_Postcondition (Node : LAL.Expr) return Boolean is
      Kind_Name : constant String := Node.Kind_Name;
      Unambiguous : Boolean := False;
   begin
      --We will only tag as unambiguous postconditions of the form: target_function'Result = value. E.g: Search'Result = 0
      if Kind_Name = "RelationOp" then
         declare
            RelOp : constant LAL.Relation_Op := Node.As_Relation_Op;
            Operator : constant String := Text.Image( RelOp.F_Op.Text );
         begin
            if Operator = "=" then --We need an equality
               if RelOp.F_Left.Kind_Name = "AttributeRef" then --We need an AttributeRef (target_function') on the left part
                  if Text.Image( RelOp.F_Left.As_Attribute_Ref.F_Attribute.Text ) = "Result" then --Attribute must be "Result"
                     Unambiguous := True;
                  end if;
               end if;
            end if;
         end;
      end if;

      return Unambiguous;
   end Unambiguous_Postcondition;


   -------Function that processes Contract_Cases in the specification of the target function
   function Process_Contracts (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin
      if Node.Kind = LALCO.Ada_Aspect_Spec
      then
         declare
            --The aspect list contains pre, post, contract_cases, etc, but here we only focus on Contract_Cases
            Aspect_List : constant LAL.Aspect_Assoc_List := Node.As_Aspect_Spec.F_Aspect_Assocs;
         begin
            for Aspect of Aspect_List loop
               if Text.Image( Aspect.F_Id.Text ) = "Contract_Cases" then
                  Put_Line("Line"
                           & Slocs.Line_Number'Image (Aspect.Sloc_Range.Start_Line)
                           & ": " & Text.Image( Aspect.Text ));
                  Nodes_Processed := True;
                  --Let's slice the different cases of the contract
                  declare
                     Cases_List : constant LAL.Assoc_List := Aspect.F_Expr.As_Aggregate.F_Assocs;
                     num_case : Integer := 1;
                  begin
                     for Contract_Case of Cases_List loop --Each case contains a guard and a consequence
                        Put_Line("Case " & num_case'Image & ":");
                        Put_Line("Guard (local pre): " & Text.Image( Contract_Case.As_Aggregate_Assoc.F_Designators.Text ));
                        Put_Line("Consequence (local post): " & Text.Image( Contract_Case.As_Aggregate_Assoc.F_R_Expr.Text ));
                        num_case := num_case + 1;
                        --We add the contract_case, guard and consequence...
                        Contract_Cases_Z3.Append( Text.Image( Contract_Case.Text ) );
                        --Local pre
                        if Text.Image( Contract_Case.As_Aggregate_Assoc.F_Designators.Text ) /= "others" then
                           for E of Contract_Case.As_Aggregate_Assoc.F_Designators loop --usually contains just one element
                              Contract_Cases_Guards_Z3.Append( Translate_Logical_Expr( E.As_Expr ));
                           end loop;
                        else  --Translation of "others" logical condition
                           Contract_Cases_Guards_Z3.Append( Translate_Others );
                        end if;
                        --Local post
                        declare
                           Local_Postcondition : PostCondition;
                        begin
                           if Unambiguous_Postcondition( Contract_Case.As_Aggregate_Assoc.F_R_Expr ) then --Expected Value
                              Local_Postcondition.Condition_Type := Value;
                              Local_Postcondition.Condition.Append( Text.Image( Contract_Case.As_Aggregate_Assoc.F_R_Expr.As_Relation_Op.F_Right.Text ) ); --'Result value
                           else  --Expected Behaviour
                              Local_Postcondition.Condition_Type := Behaviour;
                              Local_Postcondition.Condition.Append( Text.Image( Contract_Case.As_Aggregate_Assoc.F_R_Expr.Text ) ); --Future Assert content
                           end if;

                           Contract_Cases_Consequences_Z3.Append( Local_Postcondition );
                        end;
                     end loop;
                  end;
               end if;
            end loop;
         end;
      end if;

      return LALCO.Into;
   end Process_Contracts;


   -------Function that processes Global Postconditions in the specification
   function Process_Postconditions (Node : LAL.Ada_Node'Class) return LALCO.Visit_Status
   is
      use type LALCO.Ada_Node_Kind_Type;
   begin
      if Node.Kind = LALCO.Ada_Aspect_Spec
      then
         declare
            --The aspect list contains pre, post, contract_cases, etc, but here we only focus on Pre
            Aspect_List : constant LAL.Aspect_Assoc_List := Node.As_Aspect_Spec.F_Aspect_Assocs;
         begin
            for Aspect of Aspect_List loop
               if Text.Image( Aspect.F_Id.Text ) = "Post" then
                  Put_Line("Line"
                           & Slocs.Line_Number'Image (Aspect.Sloc_Range.Start_Line)
                           & ": " & Text.Image( Aspect.Text ));
                  -- We add the postcondition to the Z3 printer, defining the expected value or behaviour of the target function
                  -- Note that Global Post expressions usually are Paren_Expr that may or not contain a Relational_Op with an equality
                  -- but since they can't be a Relational_Op, to simplify, I'll consider them as expected behaviours
                  Global_Postcondition_Z3.Condition_Type := Behaviour;
                  Global_Postcondition_Z3.Condition.Append( Text.Image( Aspect.F_Expr.Text ) );   --Future Assert content

                  Nodes_Processed := True;
               end if;
            end loop;
         end;
      end if;
      return LALCO.Into;
   end Process_Postconditions;


end Node_Processing;
