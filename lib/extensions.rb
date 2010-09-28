require 'bigdecimal'

class Float 
  def to_d
    BigDecimal(self.to_s)
  end
end

class BigDecimal
  def to_finance
    if self.nonzero? && (! self.nan?)
     number = sprintf("%.2f", self)
     number.to_s.reverse.gsub(/(\d\d\d)(?=\d)(?!\d*\.)/, '\1,').reverse
    elsif self.nan?
     print self.to_s
    elsif self.nonzero?
     sprintf("%.2f", self)
    end
  end
end

class Fixnum
  def to_finance
    if self != 0
      number = sprintf("%.2f", self)
      number.to_s.reverse.gsub(/(\d\d\d)(?=\d)(?!\d*\.)/, '\1,').reverse
    else
      sprintf("%.2f", self)
    end
  end
  def to_d
    BigDecimal(self.to_s)
  end
  
end

