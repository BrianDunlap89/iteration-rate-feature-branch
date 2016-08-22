class IterationReport
  attr_reader :project, :overlapping_results, :iterations

  def initialize(project:)
    @project = project
    @iterations = IterationFactory.new(project: project).generate_iterations
  end

  def total_billable_days_by_iteration
    iterations.inject([]) do |iterations, iteration|
      find_overlapping_results(iteration)
      iterations << total_billable_days(iteration)
    end
  end

  def total_billable_days(iteration)
    return 0 if !overlapping_results
    overlapping_results.inject(0) { |total, result| total + result.iteration_adjusted_billable_days(iteration) }          overlapping_results.inject(0) { |total, result| total + result.iteration_adjusted_billable_days(iteration) }
  end

  def find_overlapping_results(iteration)
    @overlapping_results = project.results.overlapping_iteration(iteration)
  end
end
