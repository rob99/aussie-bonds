require 'bigdecimal'
require 'date'
module Financial
  module Security
    class FormulaBase
      attr_accessor :face_value
      attr_accessor :calculation_notes, :calculation_successful, :validation_errors
      attr_reader :settlement_date, :maturity_date
      attr_reader :face_value, :yield_rate
      def yield_rate=(value)
        @yield_rate = BigDecimal(value, 16)
      end
      def face_value=(value)
        @face_value = BigDecimal(value.to_s.gsub(',',''), 24)
      end

      def settlement_date=(value)
	      if value.is_a? String
    	   value = Date.strptime(value, '%Y-%m-%d')
        end
        @settlement_date = value
      end
      
      def maturity_date=(value)
      	if value.is_a? String
           value = Date.strptime(value, '%Y-%m-%d')
        end
        @maturity_date = value
      end
      def npv(amount, rate, days, day_count)
        #s = 365/d * (rate ) + 365) * a
        (day_count/(BigDecimal(days.to_s) * (rate / BigDecimal("100")) + day_count)) * amount
      end
      def price_to_yield(fv, pv, days, day_count)
        (((fv/pv) - 1) * (day_count/BigDecimal.new(days)) ) * 100
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

      def events(from, to)
        raise NotImplementedError
        {}
      end
      def map_params(args)
        args.each do |k,v|
          m = (k.to_s + '=').to_sym  
          if respond_to? m
            send(m, v)
          end
          m = (k.to_s + '=').gsub(/-/,'_').to_sym
          if respond_to? m
            send(m, v)
          end  
        end
      end
      
      
        

    end

  end
end
