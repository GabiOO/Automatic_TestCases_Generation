--In this spec I will declare everything related to the exercise 1 of chapter 3

--Chapter 3, exercise 1 Price Variable:
--A price at a product bidding site takes a dollar amount, here are the specifications
--(1) The value entered must be greater than 0 and less than 1000000
--(2) If the value is less than 10000, take action A (reject)
--(3) If the value is greater or equal to 10000, take action B (accept)
--Find equivalent partitions, select input vectors for each partition and generate test cases for the following levels
--(a)base case; (b)base worst case; (c)standard case

--The partitions would be:
--1) (-inf,0] invalid
--2) (0,10000) valid --> reject
--3) [10000,1000000) valid --> accept
--4) [1000000,+inf) invalid

package PriceVariable with
   SPARK_Mode => On
is
   type Price is delta 0.01 range 0.01 .. 999999.99; --Precision fixed at 2 decimals

   AcceptingBound : constant Price := 10000.00; --If the value is greater or equal to this bound then it is accepted, otherwise it is rejected

   function AcceptOffer ( amount : Price ) return Boolean with
     Contract_Cases => (
        amount < AcceptingBound => AcceptOffer'Result = False,
        amount >= AcceptingBound => AcceptOffer'Result = True  );

end PriceVariable;
