class ClusterHelper::JobStatistics
  STATS = [:job_count,
           :state_histogram]

  def initialize(jobs, args)
    @jobs = jobs
    @args = args
    @stats = nil
  end

  def init_stats
    @stats = {}
  end

  def job_count
    return @jobs.count
  end

  def state_histogram
    return if @jobs.empty?
    histogram = {}
    @jobs.each do |job|
      histogram[job.state] ||= 0
      histogram[job.state] += 1
    end
    histogram
  end

  def execute
    init_stats
    STATS.each do |stat|
      data = send(stat)
      @stats[stat.to_s] = data if data 
    end
  end

  def to_h
    return @stats if @stats
    execute
    @stats
  end

end
