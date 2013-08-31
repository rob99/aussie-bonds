# To change this template, choose Tools | Templates
# and open the template in the editor.

#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
#require 'treasury_note'

class TreasuryNoteTest < Test::Unit::TestCase
  def test_tnote
    f = Financial::Security::Rba::TreasuryNote.new
    f.settlement_date = Date.civil(2007, 9, 1)
    f.maturity_date = Date.civil(2008, 2, 1)
    f.face_value = 1000000
    f.yield_rate = 5.5155
    f.calculate

    assert_equal(BigDecimal.new("977402.68"), f.amount_settlement)
    assert_equal(true, f.calculation_successful)
  end
  def test_params
    h = {:settlement_date =>Date.civil(2007, 9, 1), :maturity_date=>Date.civil(2008, 2, 1), :face_value=>'1,000,000', :yield_rate=>5.5155}
    f = Financial::Security::Rba::TreasuryNote.new
    f.map_params h
    f.calculate
    
    assert_equal(BigDecimal.new("977402.68"), f.amount_settlement)
    assert_equal(true, f.calculation_successful)
    assert_equal(153, f.days_to_maturity)
  end
  def test_types
    h = {:settlement_date =>Date.civil(2007, 9, 1), :maturity_date=>Date.civil(2008, 2, 1), :face_value=>1000000, :yield_rate=>5.5155}
    f = Financial::Security::Rba::TreasuryNote.new
    f.map_params h
    f.calculate
    assert_equal("Fixnum", f.days_to_maturity.class.to_s)
  end
  def test_yield
    f = Financial::Security::Rba::TreasuryNote.new
    y = f.yield(BigDecimal.new("139.58"), BigDecimal.new("138"), 64, 365)
    assert_equal(BigDecimal.new("6.52966"), y.round(5))
  end
end
