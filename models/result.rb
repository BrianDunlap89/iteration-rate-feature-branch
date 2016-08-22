 class Result
  belongs_to :project

  # tons of code

  ## This is the query used to collect all the results that
  ## fell on the date range of a given iteration

  def self.overlapping_iteration(iteration)
    where("(start_date - ?) * (? - end_date) > 0", iteration.end_date, iteration.start_date)
  end

  # tons of code

end
