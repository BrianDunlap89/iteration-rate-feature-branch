class IterationFactory
  attr_reader :project, :iteration_rates

  def initialize(project:)
    @project = project
    @iteration_rates = project.iteration_rates.order(effective_date: :asc)
    @iteration_counter = 0
  end

  def generate_iterations
    format_iterations
  end

  private

  def format_iterations
    IterationSterilizer.new(iterations: unformatted_iterations,
                            project: project,
                            iteration_timelines: iteration_timelines
                            ).sterilize
  end

  def unformatted_iterations
    iteration_timelines.each { |timeline| build_unformatted_iterations(timeline) }
    @unformatted_iterations
  end

  def build_unformatted_iterations(timeline)
    rate = current_iteration_rate(timeline
    timeline.step(iteration_length(rate)) do |iteration_start_date|
      build_current_iteration(iteration_start_date: iteration_start_date, iteration_rate: rate)
      collect_current_iteration
    end
  end

  def build_current_iteration(iteration_start_date:, iteration_rate:)
    @iteration_counter += 1
    @current_iteration = Iteration.new(
        start_date: iteration_start_date,
        length:     iteration_length(iteration_rate),
        number:     @iteration_counter,
        end_date:   iteration_start_date + (iteration_length(iteration_rate) - 1)
      )
  end

  def collect_current_iteration
    @unformatted_iterations ||= []
    @unformatted_iterations << @current_iteration
  end

  def build_iteration_timelines
    iteration_rates.inject([]) { |timelines, rate| timelines << iteration_timeline(rate) }.compact
  end

  def iteration_timelines
    @iteration_timelines ||= build_iteration_timelines
  end

  def iteration_timeline(iteration_rate)
    return nil if iteration_rate.effective_date_exceed_today?
    if !find_next(iteration_rate) || find_next(iteration_rate).effective_date_exceed_today?
      iteration_rate.effective_date..timeline_end_date
    else
      iteration_rate.effective_date...find_next(iteration_rate).effective_date
    end
  end

  def find_next(iteration_rate)
    iteration_rates.where("effective_date > ?", iteration_rate.effective_date).first
  end

  def iteration_length(iteration_rate)
    iteration_rate * 7
  end

  def timeline_end_date
    return Date.today if project.end_date > Date.today
    project.end_date
  end

  def current_iteration_rate(iteration_timeline)
    first_day = iteration_timeline.first
    iteration_rates.find_by(effective_date: first_day).rate
  end
end
