require 'formulae/coupon_bearing_base'
require 'formulae/util'
require 'bigdecimal'
require 'formulae/extensions'


class RbaFloatingRateNote < CouponBearingBase

  attr_reader :vn, :v, :i, :default_frequency, :an
  attr_reader :trading_margin, :swap_rate, :discount_next, :coupon_basis_rate, :interest_margin, :days_basis
  
  def trading_margin=(value)
    @trading_margin = value.to_d
  end
  def swap_rate=(value)
    @swap_rate = value.to_d
  end
  def discount_next=(value)
    @discount_next = value.to_d
  end
  def coupon_basis_rate=(value)
    @coupon_basis_rate = value.to_d
  end
  def interest_margin=(value)
    @interest_margin=value.to_d
  end
  def days_basis=(value)
    @days_basis=value.to_d
  end
  
  def initialize
    @default_frequency = 4
    @discount_mode = false
    @days_basis = BigDecimal("365")
    @frequency = @default_frequency.to_d
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
    if (! @interest_margin)
      @validation_errors.push("Interest Margin required")
    end
    if (! @coupon_basis_rate)
      @validation_errors.push("Coupon Basis Rate required")
    end
    
    if (! @trading_margin)
      @validation_errors.push("Trading Margin required")
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
      
    coupon_rate = @interest_margin + @coupon_basis_rate
    big_frequency = @frequency * 100
    
    if (! @override_coupon_period_calc)
      @next_coupon_date = CouponBearingBase.calculate_next_coupon_date(@settlement_date, @maturity_date, @frequency)
      @previous_coupon_date = CouponBearingBase.calculate_previous_coupon_date(@settlement_date, @maturity_date, @frequency)
    end
    
    @num_complete_periods_remaining = CouponBearingBase.remaining_coupon_periods(@settlement_date, @maturity_date, @frequency)
    
    if ((! @override_discount_calc)  && (@num_complete_periods_remaining == 0 || (@num_complete_periods_remaining ==1 && @ex_interest)))
      @calculation_notes.push("Discount mode")
      @discount_mode = true
      if (@num_complete_periods_remaining > 0)
        @calculation_notes.push("Warning - Final coupon payment not yet known!")
      end
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
    @i = (@trading_margin + @swap_rate) / big_frequency
    @v =  1 / (1 + @i)
    @vn = @v ** @num_complete_periods_remaining
    @an = (1 - @vn) / @i
    @days_to_maturity = @effective_maturity_date - @settlement_date
    #@next_coupon_amount = (((@interest_margin + @coupon_basis_rate) / @days_basis) * @days_in_current_period) / BigDecimal("100") * @face_value
    
    @amount_next_coupon = coupon_rate * @days_in_current_period.to_d / @days_basis
    
    @ex_int_flag = 1
    if (@ex_interest)
      @ex_int_flag = 0
    end
    
    if (@discount_mode)
      @amount_settlement = Util.npv(@face_value + (@interest_margin + @coupon_basis_rate), @discount_next, @days_to_maturity, @days_basis)
      @amount_settlement = @amount_settlement.round(2)
      @pph_settlement = @amount_settlement / (@face_value + @amount_next_coupon);
    else
      # (((B12+B11)*I16)*(F5/365)+((B12-B13)/B17)*((1-(1+((B13+B15)/(B17*100)))^-F11)/((B13+B15)/(B17*100)))+100)/(1+(B14+B13)*(F6/36500))
      
      #      ((1-(1+((B13+B15)/(B17*100)))^-F11)/((B13+B15)/(B17*100)))    
      
      @pph_settlement = ((coupon_rate * @ex_int_flag) * (@days_in_current_period.to_d / @days_basis) + ((@interest_margin - @trading_margin) / @frequency) * 
      ((1 - (1 + @i) ** (@num_complete_periods_remaining * -1)) / ((@trading_margin + @swap_rate) / big_frequency)) + 100) / 
      (1 + (@discount_next + @trading_margin) * (@days_to_next_coupon.to_d / (@days_basis * 100)));
      
      #puts "eif " + @ex_int_flag.class.to_s
      #puts coupon_rate.class.to_s
      #puts "dicp " + @days_in_current_period.class.to_s
      #puts @days_basis.class.to_s
      #puts "im " + @interest_margin.class.to_s
      #puts @trading_margin.class.to_s
      #puts "an " + @an.class.to_s
      #puts @discount_next.class.to_s
      
      #puts @an.round(20).to_s
      #@pph_settlement = @ex_int_flag * @amount_next_coupon + (((@interest_margin - @trading_margin) /4 ) * @an) + 1
      #@pph_settlement = @pph_settlement + 100
      #puts "Step 2: " + @pph_settlement.round(20).to_s

      #@pph_settlement = @pph_settlement / (1 + (((@discount_next + @trading_margin) * @days_to_next_coupon.to_d)/ 365))
      #puts @pph_settlement.round(20).to_s
      #puts "Next coup: " + @amount_next_coupon.to_s
      
      @pph_settlement = @pph_settlement.round(@pph_rounding_settlement)
      @amount_settlement = (@pph_settlement * (@face_value / 100)).round(2)      
    end
    
    if @ex_interest
      @pph_interest = (- @days_to_next_coupon.to_d) / @days_basis * (@interest_margin + @coupon_basis_rate)
    else
      @pph_interest = (@days_in_current_period - @days_to_next_coupon).to_d / @days_basis * (coupon_rate)
    end

    @pph_interest = @pph_interest.round(@pph_rounding_interest)
    @pph_capital = @pph_settlement - @pph_interest
    @amount_interest = (@pph_interest * (@face_value / BigDecimal("100"))).round(2)
    @amount_capital = @amount_settlement - @amount_interest
    @calculation_sucessful = true
      
  end


end
