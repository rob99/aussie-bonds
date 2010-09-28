require 'bigdecimal'
module Financial
  module Security
    class Util
  
      def Util.round(float, num_of_decimal_places)
        #puts "-> " + @float.to_s
        @exponent = num_of_decimal_places
        @float = float*(BigDecimal("10.0")**@exponent)
        @float = @float.round
        @float = @float / (BigDecimal("10.0")**@exponent)
        #puts "<- " + @float.to_s
        return @float
      end
  


    end

  end
end