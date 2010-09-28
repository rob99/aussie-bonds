require 'financial/security/coupon_bearing_base'
#require 'formulae/util'
#require 'bigdecimal'
require 'extensions'

module Financial
  module Security
    module Rba
      class FixedInterest < Financial::Security::CouponBearingBase

        attr_reader :g, :an, :vn, :v, :i
        attr_reader :yield_rate
        def yield_rate=(value)
          @yield_rate = BigDecimal(value.to_s)
        end

        def initialize
          @discount_mode = false
          @frequency = 2
          @pph_rounding_interest = 3
          @pph_rounding_settlement = 3
          @ex_interest_days = 7
          @override_discount_calc = false
          @override_ex_int_calc = false
          @override_coupon_period_calc = false
          @discount_mode = false
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
          if (! @coupon_rate)
            @validation_errors.push("Coupon Rate required")
          end
          if (! @yield_rate)
            @validation_errors.push("Yield Rate required")
          end
          if (@override_coupon_period_calc && (! @previous_coupon_date))
            @validation_errors.push("Previous Coupon date required when Coupon Period Calculation Override on")
          end
          if (@override_coupon_period_calc && (! @next_coupon_date))
            @validation_errors.push("Next Coupon date required when Coupon Period Calculation Override on")
          end
          if (! @face_value)
            @validation_errors.push("Face Value required")
          end

          if (@validation_errors.size > 0)
            @amount_settlement = BigDecimal("0")
            @amount_capital = BigDecimal("0")
            @amount_interest = BigDecimal("0")
            return
          end

          if (! @override_coupon_period_calc)
            @next_coupon_date = CouponBearingBase.calculate_next_coupon_date(@settlement_date, @maturity_date, @frequency)
            @previous_coupon_date = CouponBearingBase.calculate_previous_coupon_date(@settlement_date, @maturity_date, @frequency)
          else
            @calculation_notes.push("Warning - Override Coupon Period Calc is switched on!")
          end
          if @override_ex_int_calc
            @calculation_notes.push "Override Ex-Interest Calc is set to true, and seems to be incorrect"
          else
            @ex_interest = (@next_coupon_date - @settlement_date <= @ex_interest_days)
          end

          @num_complete_periods_remaining = CouponBearingBase.remaining_coupon_periods(@settlement_date, @maturity_date, @frequency)

          if ((! @override_discount_calc)  && (@num_complete_periods_remaining == 0 || (@num_complete_periods_remaining ==1 && @ex_interest)))
            @calculation_notes.push("Discount mode")
            @discount_mode = true
          else
            @discount_mode = false
          end

          # TODO: fix up how effective coupon date behaves
          # for now just push weekends out to monday
          @effective_maturity_date = @maturity_date
          if  @discount_mode
            if @maturity_date.wday ==0
              @effective_maturity_date = @effective_maturity_date + 1
              @calculation_notes.push("Sunday maturity adjusted to Monday")
            elsif @maturity_date.wday == 6
              @effective_maturity_date = @effective_maturity_date + 2
              @calculation_notes.push("Saturday maturity adjusted to Monday")
            end
          end

          @days_in_current_period = @next_coupon_date - @previous_coupon_date
          @days_to_next_coupon = @next_coupon_date - @settlement_date
          @g = @coupon_rate / BigDecimal(@frequency.to_s)
          @i = @yield_rate / (@frequency * BigDecimal("100"))
          @v = BigDecimal("1") / (1 + @i)
          @vn = @v ** @num_complete_periods_remaining
          @an = (1 - @vn) / @i
          @days_to_maturity = @effective_maturity_date - @settlement_date
          @amount_next_coupon = @g / BigDecimal("100") * @face_value
          @ex_int_flag = 1
          if (@ex_interest)
            @ex_int_flag = 0
          end

          if @ex_interest
            @pph_interest = (BigDecimal.new(@days_to_next_coupon.to_s) / BigDecimal.new(@days_in_current_period.to_s)) * @g * -1
          else
            @pph_interest = @g * ((@days_in_current_period - @days_to_next_coupon) / @days_in_current_period)
          end

          if (@discount_mode)
            @pph_rounding_interest = 12
            @amount_settlement = npv(@face_value + @amount_next_coupon, @yield_rate, @days_to_maturity, 365).round(2)
            @amount_interest = (@pph_interest * (@face_value / 100)).round(2)
            @pph_interest = @amount_interest / @face_value * 100
            @pph_capital = @amount_settlement / @face_value * 100
            if @ex_interest && @next_coupon_date != @maturity_date
                # second last ex - compensate for coupon
                @amount_settlement -= @amount_interest
            end
            @amount_capital = @amount_settlement - @amount_interest
            @pph_settlement = (@amount_settlement / (@face_value / 100)).round(10)
          else
            # bignumber does not support power to decimal - use float
            part1 = BigDecimal((@v.to_f ** (@days_to_next_coupon / @days_in_current_period)).to_s, 24)
            @pph_settlement = part1 * ((@g * (@ex_int_flag + @an)) + (BigDecimal("100", 0) * @vn))
            @pph_settlement = @pph_settlement.round(@pph_rounding_settlement)
            @amount_settlement = (@pph_settlement * (@face_value / 100)).round(2)
            @amount_interest = (@pph_interest * (@face_value / BigDecimal("100"))).round(2)
            @amount_capital = @amount_settlement - @amount_interest
            @pph_interest = BigDecimal(@pph_interest.to_s).round(@pph_rounding_interest)
            @pph_capital = @pph_settlement - @pph_interest
          end

          #puts @amount_interest
          #puts "In F - AI:"  + @amount_interest.to_s + " FV: " + @face_value.to_s + " AI PPH: " + @pph_interest.to_s + " FV class: " + @face_value.class.to_s
          @calculation_successful = true

        end


      end
    end
  end
end