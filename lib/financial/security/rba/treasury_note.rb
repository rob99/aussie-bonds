require 'financial/security/formula_base'
module Financial
  module Security
    module Rba
      class TreasuryNote < FormulaBase
        attr_accessor :amount_interest, :days_to_maturity, :days_in_year
        attr_reader :amount_settlement
        def amount_settlement=(value)
          @amount_settlement = BigDecimal(value.to_s.gsub(',',''))
        end
        def initialize
          @settlement_date = Date.today
          @face_value = BigDecimal("0")
          @days_in_year = 365
        end

        def calculate
          calculate_settlement
        end
        def calculate_yield
          validate
          if (! @amount_settlement)
            @validation_errors.push("Settlement Amount required")
          end
          if (@validation_errors.size > 0)
            @yield_rate = BigDecimal("0")
            @amount_interest = BigDecimal("0")
            return
          end
          @effective_maturity_date = @maturity_date
          
          @days_to_maturity = (@effective_maturity_date - @settlement_date).to_i

          @yield_rate = price_to_yield(@face_value, @amount_settlement, @days_to_maturity, @days_in_year)
          @yield_rate = @yield_rate.round(@face_value.truncate.to_s.size)
          @amount_interest = @face_value - @amount_settlement
          @calculation_successful = true
        end

        def validate
          @calculation_notes = Array.new
          @validation_errors = Array.new
          @calculation_successful = false
          if (! @settlement_date)
            @validation_errors.push("Settlement Date required")
          end
          if (! @maturity_date)
            @validation_errors.push("Maturity Date required")
          end
          if ((@maturity_date && @settlement_date) && @maturity_date < @settlement_date)
            @validation_errors.push("Maturity Date must be on or after Settlement Date")
          end
         
          if (! @face_value)
            @validation_errors.push("Face Value required")
          end

        end
        def calculate_settlement
          validate
          if (! @yield_rate)
            @validation_errors.push("Yield Rate required")
          end
          if (@validation_errors.size > 0)
            @amount_settlement = BigDecimal("0")
            @amount_interest = BigDecimal("0")
            return
          end
          @effective_maturity_date = @maturity_date

          @days_to_maturity = (@effective_maturity_date - @settlement_date).to_i

          @amount_settlement = npv(@face_value, @yield_rate, @days_to_maturity, @days_in_year).round(2)
          @amount_interest = @face_value - @amount_settlement
          @calculation_successful = true 
        end
      end

      EVENTS = [:issue, :settlement, :maturity]
      def events(from, to)
        retn = []
        retn << {:date=>@maturity_date, :event=>:maturity} if @maturity_date && @maturity_date >= from && @maturity_date <= to
        retn << {:date=>@issue_date, :event=>:issue} if @issue_date && @issue_date >= from && @issue_date <= to
        retn << {:date=>@settlement_date, :event=>:issue} if @settlement_date && @settlement_date >= from && @settlement_date <= to
        retn
      end
      
      
      
      
    end
  end
end
