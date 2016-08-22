class Project < ActiveRecord::Base
  has_many :results
  has_many :iteration_rates

  # tons of code
end
