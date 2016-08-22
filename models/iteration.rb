class Iteration
  attr_reader :start_date, :number, :end_date
  attr_accessor :length

  def initialize(start_date:, end_date: nil, number: nil, length: nil)
    @start_date = start_date
    @end_date = end_date
    @number = number
    @length = length
  end

  def in_progress?
    Date.today > start_date && Date.today <= end_date
  end
end
