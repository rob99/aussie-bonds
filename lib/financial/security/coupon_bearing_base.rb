require 'date'
require 'time'
require 'active_support/core_ext'
require 'financial/security/formula_base'
module Financial
  module Security

    class CouponBearingBase < Financial::Security::FormulaBase
  
      def coupon_rate=(value)
        @coupon_rate = BigDecimal(value.to_s, 24)
      end
      attr_reader :coupon_rate
      attr_accessor :next_coupon_date, :previous_coupon_date, :effective_maturity_date
      attr_accessor :frequency
      # days
      attr_accessor :days_to_next_coupon, :days_in_current_period, :days_to_maturity
      attr_accessor :num_complete_periods_remaining
      attr_accessor :ex_interest, :ex_interest_days, :days_remaining_in_current_period
      attr_accessor :pph_rounding_interest, :pph_rounding_settlement
      attr_accessor :override_discount_calc, :override_ex_interest_calc, :override_coupon_period_calc
      attr_accessor :discount_mode
      # pph
      attr_accessor :pph_settlement, :pph_interest, :pph_capital
      # amounts
      attr_accessor :amount_settlement, :amount_interest, :amount_capital
      attr_accessor :amount_next_coupon
  
      def self.remaining_coupon_periods(settlement_date, maturity_date, frequency)
        test_date = maturity_date.to_time.months_ago(12/frequency)
        last_date = maturity_date
        coupons = 0
        while (test_date.to_date > settlement_date)
          last_date = test_date
          test_date = test_date.to_time.months_ago(12/frequency)
          coupons += 1
        end
        coupons
      end
    
      def self.calculate_next_coupon_date(settlement_date, maturity_date, frequency)
        test_date = maturity_date.to_datetime.months_ago(12/frequency)
        last_date = maturity_date
        while test_date.to_date > settlement_date
          last_date = test_date
          test_date = test_date.to_time.months_ago(12/frequency)
        end
        last_date.to_date
      end
  
      def self.calculate_previous_coupon_date(settlement_date, maturity_date, frequency)
        test_date = maturity_date.to_time.months_ago(12/frequency)
        last_date = maturity_date
        while test_date > settlement_date.to_time
          last_date = test_date
          test_date = test_date.to_time.months_ago(12/frequency)
        end
        test_date.to_date
      end
  
    end
  end
end