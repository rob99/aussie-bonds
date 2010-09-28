require 'formulae/coupon_bearing_base'
require 'formulae/util'
require 'bigdecimal'
require 'formulae/extensions'


class RbaCapitalIndexed < CouponBearingBase

  attr_reader :g, :an, :vn, :v, :p
  attr_reader :yield_rate, :k_t_1, :k_t, :cpi_t, :cpi_t_2, :pph_indexation, :amount_indexation
  def yield_rate=(value)
    @yield_rate = BigDecimal(value.to_s)
  end
  def cpi_t=(value)
    @cpi_t = BigDecimal(value.to_s)
  end
  def cpi_t_2=(value)
    @cpi_t_2 = BigDecimal(value.to_s)
  end
  def k_t_1=(value)
    @k_t_1 = BigDecimal(value.to_s)
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
    if (! @settlement_date) then @validation_errors.push("Settlement Date required") end
    if (! @maturity_date) then @validation_errors.push("Maturity Date required") end
    if ((@maturity_date && @settlement_date) && @maturity_date < @settlement_date) then @validation_errors.push("Maturity Date must be on or after Settlement Date") end
    if (! @coupon_rate) then @validation_errors.push("Coupon Rate required") end
    if (! @yield_rate) then @validation_errors.push("Yield Rate required") end
    if (@override_coupon_period_calc && (! @previous_coupon_date)) then @validation_errors.push("Previous Coupon date required when Coupon Period Calculation Override on") end
    if (@override_coupon_period_calc && (! @next_coupon_date)) then @validation_errors.push("Next Coupon date required when Coupon Period Calculation Override on") end
    if (! @face_value) then @validation_errors.push("Face Value required") end
    if (! @cpi_t) then @validation_errors.push("CPI(t) required") end
    if (! @cpi_t_2) then @validation_errors.push("CPI(t-2) required") end
    if (! @kt) then @validation_errors.push("K(t-1) required") end  
    
    if (@validation_errors.size > 0)
      @amount_settlement = BigDecimal("0")
      @amount_capital = BigDecimal("0")
      @amount_interest = BigDecimal("0")
      return
    end
      
    if (! @override_coupon_period_calc)
      @next_coupon_date = CouponBearingBase.calculate_next_coupon_date(@settlement_date, @maturity_date, @frequency)
      @previous_coupon_date = CouponBearingBase.calculate_previous_coupon_date(@settlement_date, @maturity_date, @frequency)
    end
    
    @num_complete_periods_remaining = CouponBearingBase.remaining_coupon_periods(@settlement_date, @maturity_date, @frequency)
    
    if (@num_complete_periods_remaining == 0 || (@num_complete_periods_remaining ==1 && @ex_interest))
      @calculation_notes.push("Discount mode")
      @discount_mode = true
    else
      @discount_mode = false
    end
    
    @p = (100 / 2) * ((@cpi_t / @cpi_t_2) - 1)
    @k_t = @k_t_1 * (1 + (p / 100))
    @days_in_current_period = @next_coupon_date - @previous_coupon_date
    @days_to_next_coupon = @next_coupon_date - @settlement_date
    @g = @coupon_rate / BigDecimal(@frequency.to_s)
    @i = @yield_rate / (@frequency * BigDecimal("100"))
    @v = BigDecimal("1") / (1 + @i)
    @vn = @v ** @num_complete_periods_remaining
    @an = (1 - @vn) / @i
    @days_to_maturity = @maturity_date - @settlement_date
    @next_coupon_amount = @g / BigDecimal("100") * @face_value
    @ex_int_flag = 1
    if (@ex_interest)
      @ex_int_flag = 0
    end
    
    if (@discount_mode)
      @amount_settlement = Util.npv(@face_value + @next_coupon_amount, @yield_rate, @days_to_maturity, 365)
      @amount_settlement = Util.round(@amount_settlement, 2)
      @pph_settlement = @amount_settlement / (@face_value + @next_coupon_amount)
    else
      # bignumber does not support power to decimal - use float
      @part1 = BigDecimal((@v.to_f ** (@days_to_next_coupon / @days_in_current_period)).to_s, 24)
      @pph_settlement = (@v ** (@f / @d)) * (@g * (@ex_int_flag + @an) + (100 * @vn)) * ((@k_t * ((1 + @p / 100) ** (- @f / @d))) / 100)
      @pph_settlement = @pph_settlement.round(@pph_rounding_settlement)
      @amount_settlement = (@pph_settlement * (@face_value / BigDecimal("100"))).round(2)
    end
    
    if @ex_interest
      @pph_interest = (@days_to_next_coupon / @days_in_current_period).to_d * @g * -1
    else
      @pph_interest = @g * ((@days_in_current_period - @days_to_next_coupon) / @days_in_current_period)
    end

    @pph_interest = BigDecimal(@pph_interest.to_s).round(@pph_rounding_interest)
    @pph_capital = @pph_settlement - @pph_interest
    #puts @amount_interest
    @amount_interest = (@pph_interest * (@face_value / BigDecimal("100"))).round(2)
    #puts @amount_interest
    #puts "In F - AI:"  + @amount_interest.to_s + " FV: " + @face_value.to_s + " AI PPH: " + @pph_interest.to_s + " FV class: " + @face_value.class.to_s
    @amount_capital = @amount_settlement - @amount_interest
    @calculation_successful = true
      
  end


end
