class IterationRate < ActiveRecord::Base
  belongs_to :project

  def effective_date_exceed_today?
    effective_date > Date.today
  end
end
