# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'treasury_note'

class TreasuryNoteTest < Test::Unit::TestCase
  def test_tnote
    f = Financial::Security::Rba::TreasuryNote.new
    f.settlement_date = Date.civil(2007, 9, 1)
    f.maturity_date = Date.civil(2008, 2, 1)
    f.face_value = 1000000
    f.yield_rate = 5.5155
    f.calculate

    assert_equal(BigDecimal.new("977402.68"), f.amount_settlement)
    assert_equal(true, f.calculation_sucessful)
  end
end
