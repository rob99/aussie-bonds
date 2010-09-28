
require 'bigdecimal'
require 'formulae/formulae_base'

class CouponBearingAccrueClose
  
  # formula1 is the original trade
  # formula2 has the accrue/closeout date and rate
  # formula3 has the adjusted book value as at the accrue/closeout date
  attr_reader :formula1, :formula2, :formula3
  attr_reader :total_accrued_interest
  attr_reader :prem_disc_straight, :prem_disc_constant
  attr_reader :days_holding
  attr_reader :realised_pl
  attr_reader :calculation_notes, :validation_errors
  
  def calculate(formula1, formula2)
    @validation_errors = Array.new
    @calculation_notes = Array.new
    
    if ! formula1.responds_to?(:calculate)
      @validation_errors.push("formula1 has no calculate method")
    else
      @formula1 = formula1
    end
    if ! formula2.responds_to?(:calculate)
      @validation_errors.push("formula2 has no calculate method")
    else
      @formula2 = formula2
    end
    
    if (@validation_errors.size > 0)
      return
    end
    
    @formula1.calculate
    @formula2.calculate
    @formula3 = @formula.clone
    @formula3.settlement_date = @formula1.settlement_date
    @formula3.calculate
    
    @holding_days = @formula2.settlement_date - @formula2.settlement_date
    @total_accrued_interest = 0
    @prem_disc_constant = @formula1.amount_capital - @formula3.amount_capital
    @prem_disc_straight = ((@formula1.amount_capital - @formula1.amount_face_value) / @formula1.days_to_maturity) * @holding_days
    @realised_pl = @formula2.amount_settlement - @formula3.amount_settlement
    
  end
  
  
end
