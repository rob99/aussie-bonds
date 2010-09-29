# To change this template, choose Tools | Templates
# and open the template in the editor.

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


          # TODO: fix up how effective coupon date behaves
          # for now just push weekends out to monday
          @effective_maturity_date = @maturity_date

          @days_to_maturity = @effective_maturity_date - @settlement_date

          @amount_settlement = npv(@face_value + @amount_next_coupon, @yield_rate, @days_to_maturity, 365).round(2)
          @amount_interest = @face_value - @amount_settlement
          @calculation_successful = true
        end
      end
    end
  end
end
