require 'test/helper'
require 'date'
require 'financial/security/rba/fixed_interest'

class TestAussieBonds < Test::Unit::TestCase
  def test_rba_fi_ex
    f = Financial::Security::Rba::FixedInterest.new
    f.settlement_date = Date.civil(2007, 1, 25)
    f.maturity_date = Date.civil(2008, 2, 1)
    f.face_value = 1000000
    f.coupon_rate = 6.75
    f.yield_rate = 5.51
    f.calculate

    assert_equal(BigDecimal.new("101.214"), f.pph_capital)
    assert_equal(BigDecimal.new("-0.128"), f.pph_interest)
    assert_equal(BigDecimal.new("101.086"), f.pph_settlement)
    assert_equal(BigDecimal.new("1010860"), f.amount_settlement)
  end

  def test_rba_fi_cum

    f = Financial::Security::Rba::FixedInterest.new
    f.settlement_date = Date.civil(2007, 1, 1)
    f.maturity_date = Date.civil(2008, 2, 1)
    f.face_value = 1000000
    f.coupon_rate = 6.75
    f.yield_rate = 5.5155
    f.calculate

    assert_equal(BigDecimal.new("101.276"), f.pph_capital)
    assert_equal(BigDecimal.new("2.806"), f.pph_interest)
    assert_equal(BigDecimal.new("104.082"), f.pph_settlement)
    assert_equal(BigDecimal.new("1040820"), f.amount_settlement)
  end

  def test_rba_fi_2nd_last

    f = Financial::Security::Rba::FixedInterest.new
    f.settlement_date = Date.civil(2007, 7, 25)
    f.maturity_date = Date.civil(2008, 2, 1)
    f.face_value = 1000000
    f.coupon_rate = 6.75
    f.yield_rate = 5.5155
    f.calculate

    assert_equal(181, f.days_in_current_period)
    assert_equal(7, f.days_to_next_coupon)
    assert_equal(191, f.days_to_maturity)
    assert_equal(true, f.ex_interest)
    assert_equal(Date.civil(2007, 8, 1), f.next_coupon_date)
    assert_equal(BigDecimal.new("3.375"), f.g)
    assert_equal(BigDecimal.new("-0.130525"), f.pph_interest)
    assert_equal(BigDecimal.new("33750"), f.amount_next_coupon)
    assert_equal(BigDecimal.new("1006056.20"), f.amount_settlement)
    assert_equal(BigDecimal.new("100.60562"), f.pph_settlement)
    
    assert_equal(BigDecimal.new("100.475095"), f.pph_capital)
    
  end

  def test_rba_fi_discount

    f = Financial::Security::Rba::FixedInterest.new
    f.settlement_date = Date.civil(2007, 9, 1)
    f.maturity_date = Date.civil(2008, 2, 1)
    f.face_value = 1000000
    f.coupon_rate = 6.75
    f.yield_rate = 5.5155
    f.calculate

    assert_equal(BigDecimal.new("33750"), f.amount_next_coupon)
    assert_equal(BigDecimal.new("1004703.88"), f.amount_capital)
    #assert_equal(BigDecimal.new("2.806"), f.pph_interest)
    assert_equal(BigDecimal.new("101.039002"), f.pph_settlement)
    assert_equal(BigDecimal.new("1010390.02"), f.amount_settlement)
  end

    def test_rba_fi_discount

    f = Financial::Security::Rba::FixedInterest.new
    f.settlement_date = Date.civil(2007, 9, 1)
    f.maturity_date = Date.civil(2008, 2, 1)
    f.face_value = 1000000
    f.coupon_rate = 6.75
    f.yield_rate = 5.5155
    f.calculate

    assert_equal(BigDecimal.new("33750"), f.amount_next_coupon)
    assert_equal(BigDecimal.new("1004703.88"), f.amount_capital)
    assert_equal(BigDecimal.new("101.039002"), f.pph_settlement)
    assert_equal(BigDecimal.new("1010390.02"), f.amount_settlement)
  end

end
