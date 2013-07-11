require "date"

class Week
  attr_reader :year, :number

  def self.all_between(a, b)
    raise("WERKT NOG NIET") if  (a.year != b.year)
    ((a.number)..(b.number)).collect do |nr|
      Week.new(a.year, nr)
    end
  end

  def initialize(year, number)
    @year = year
    @number = number
  end

  def monday
    day 1
  end

  def sunday
    day 7
  end

  def day day_nr
    Date.commercial(@year, @number, day_nr)
  end
end
