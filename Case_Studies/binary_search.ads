package Binary_Search
  with SPARK_Mode
is
   ----------------------------------------------------
   --     SPARK 2014 - Binary_Search Example         --
   --                                                --
   -- This example illustrates the specification of  --
   -- a simple search function.                      --
   ----------------------------------------------------

   type Ar is array (1 .. 10) of Integer; 

   function Search (A : Ar; I : Integer) return Integer with
     -- A is sorted
     Pre  => (for all I1 in A'Range =>
                (for all I2 in I1 .. A'Last =>
                   A (I1) <= A (I2))),
     -- If I exists in A, then Search'Result indicates its position
     Contract_Cases => (  
	(for some Index in A'Range => A(Index) = I) => Search'Result in A'Range and A(Search'Result) = I,
        (for all Index in A'Range => A(Index) /= I) => Search'Result = 0 );

end Binary_Search;
