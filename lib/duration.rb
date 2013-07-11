class Duration
  def self.from_start_end_time(start_t, end_t, type)
    duration = end_t.to_i - start_t.to_i
    new(duration, type)
  end

  def initialize(duration, type=nil)
    @pause = type == :pause
    @duration = duration
  end

  def to_s
    "#{"-" if @pause}%d:%02d" % [hours, minutes]
  end

  def to_i
    unless @pause
      @duration
    else
      - @duration
    end
  end

  def hours
    hours = @duration / (60 * 60)
  end

  def minutes
    minutes = (@duration - (hours * 60 * 60)) / 60
  end

  def +(other)
    raise("Other should also be duration") unless other.kind_of?(Duration)

    Duration.new(self.to_i + other.to_i)
  end

  def -(other)
    raise("Other should also be duration") unless other.kind_of?(Duration)

    Duration.new(self.to_i - other.to_i)
  end
end
