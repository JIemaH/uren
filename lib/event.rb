class Event
  attr_reader :title, :status, :start_time, :end_time, :type

  def initialize(title, status, start_time, end_time, type = :work)
    @type = type
    @title = title
    @status = status
    if start_time.kind_of?(DateTime)
      @start_time = start_time
    else
      @start_time = DateTime.parse(start_time)
    end

    if end_time.kind_of?(DateTime)
      @end_time = end_time
    else
      @end_time = DateTime.parse(end_time)
    end
  end

  def duration
    @duration ||= Duration.from_start_end_time(@start_time.to_time, @end_time.to_time, @type)
  end

  def ==(other)
    raise("can only compare to other event") unless other.kind_of?(Event)

    @start_time == other.start_time && @end_time == other.end_time
  end

  def ===(other)
    self.==(other)
  end
end
