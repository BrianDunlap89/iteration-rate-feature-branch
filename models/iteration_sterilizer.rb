class IterationSterilizer
  attr_reader :iterations, :project, :iteration_timelines

  def initialize(iterations:, project:, iteration_timelines:)
    @iterations = iterations
    @project = project
    @iteration_timelines = iteration_timelines
  end

  def sterilize
    return iterations if !partial_iterations?
    remove_last_iteration if last_iteration_exceed_timeline?
    add_partial_iterations
  end

  private

  def partial_iterations?
    first_iteration.start_date != project.start_date || last_iteration.end_date != last_timeline_end_date
  end

  def last_iteration_exceed_timeline?
    last_iteration.end_date > last_timeline_end_date
  end

  def add_partial_iterations
    return iterations.insert(0, partial_iteration) if iterations.count == 0
    iterations.insert(0, first_partial_iteration) if first_iteration_partial?
    iterations.insert(-1, last_partial_iteration) if last_iteration_partial?
  end

  def first_iteration_partial?
    return nil if iterations.count == 0
    first_iteration.start_date != project.start_date
  end

  def last_iteration_partial?
    last_iteration.end_date != last_timeline_end_date
  end

  def partial_iteration
   length = (last_timeline_end_date - project.start_date).to_i + 1
   Iteration.new(start_date: project.start_date, end_date: last_timeline_end_date, number: 1, length: length )
  end

  def first_partial_iteration
    iteration_length = iteration_length(start_date: project.start_date, end_date: first_iteration.start_date.prev_day)
    Iteration.new(start_date: project.start_date,
                  end_date: first_iteration.start_date.prev_day,
                  number: 0,
                  length: iteration_length)
  end

  def last_partial_iteration
    iteration_length = iteration_length(start_date: last_iteration.end_date.next_day, end_date: last_timeline_end_date)
    Iteration.new(start_date: last_iteration.end_date.next_day,
                  end_date: last_timeline_end_date,
                  number: last_iteration.number + 1,
                  length: iteration_length)
  end

  def first_iteration
   iterations[0]
  end

  def remove_last_iteration
    iterations.delete_at(-1)
  end

  def last_iteration
    iterations[-1]
  end

  def iteration_length(start_date:, end_date:)
    end_date - start_date + 1
  end

  def last_timeline_end_date
    last_timeline = iteration_timelines.last
    last_timeline.last
  end
end
