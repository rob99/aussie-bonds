require 'bigdecimal'
module Financial
  module Security
    class FormulaBase
      attr_accessor :face_value
      attr_accessor :calculation_notes, :calculation_sucessful, :validation_errors
      attr_accessor :settlement_date, :maturity_date
      attr_reader :face_value
      def yield_rate=(value)
        @yield_rate = BigDecimal(value.to_s, 24)
      end
      def face_value=(value)
        @face_value = BigDecimal(value.to_s, 24)
      end

      def npv(amount, rate, days, day_count)
        return (day_count/(BigDecimal(days.to_s) * (rate / BigDecimal("100")) + day_count)) * amount
      end

      def round(float, num_of_decimal_places)
        #puts "-> " + @float.to_s
        @exponent = num_of_decimal_places
        @float = float*(BigDecimal("10.0")**@exponent)
        @float = @float.round
        @float = @float / (BigDecimal("10.0")**@exponent)
        #puts "<- " + @float.to_s
        return @float
      end
    end

    def events(from, to)
      raise NotImplementedError
      {}
    end
  end
end