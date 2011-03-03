require 'financial/security/formula_base'
module Financial
  module Security
    module Rba
      class TreasuryNote < FormulaBase
        def initialize
          @settlement_date = Date.today
          @face_value = BigDecimal("0")
        end

        def calculate
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
          if (! @yield_rate)
            @validation_errors.push("Yield Rate required")
          end
          if (! @face_value)
            @validation_errors.push("Face Value required")
          end

          if (@validation_errors.size > 0)
            @amount_settlement = BigDecimal("0")
            @amount_interest = BigDecimal("0")
            return
          end
          @effective_maturity_date = @maturity_date

          @days_to_maturity = @effective_maturity_date - @settlement_date

          @amount_settlement = npv(@face_value, @yield_rate, @days_to_maturity, 365).round(2)
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
