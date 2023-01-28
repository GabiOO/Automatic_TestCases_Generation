with Ada.Text_IO; use Ada.Text_IO;

package body PriceVariable with
   SPARK_Mode => On
is

   function AcceptOffer ( amount : Price ) return Boolean is
      result : Boolean := False;
   begin

      if (amount >= AcceptingBound) then
         result := True;
      end if;

      return result;

   end AcceptOffer;

end PriceVariable;
