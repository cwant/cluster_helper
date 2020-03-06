require_relative 'concerns/time_readable'

class ClusterHelper::JobStatistics

  include TimeReadable

  STATS = {
    'job_count' => :job_count,
    'time_in_queue' => :waiting_in_queue,
    'running_time' => :running_time,
    'frequencies' => {
      'states' => :state_frequency,
      'users' => :user_frequency,
      'accounts' => :account_frequency
    }.freeze,
    'efficiency' => :efficiency
  }.freeze

  def initialize(jobs, args = {})
    @jobs = jobs
    @args = args
    @stats = nil
  end

  def init_stats
    @stats = {}
  end

  def job_count
    @jobs.count
  end

  def state_frequency
    generic_frequency('state', &:state)
  end

  def user_frequency
    generic_frequency('username') do |job|
      job.user.username
    end
  end

  def account_frequency
    generic_frequency('account') do |job|
      job.account.name
    end
  end

  def execute
    init_stats
    @stats = execute_node(STATS)
  end

  def execute_node(node)
    out = {}
    node.each do |name, stat|
      data = if stat.is_a?(Hash)
               execute_node(stat)
             else
               send(stat)
             end
      out[name] = data if data
    end
    return nil if out.empty?
    out
  end

  def to_h
    return @stats if @stats
    execute
    @stats
  end

  def waiting_in_queue
    total_waiting_time_seconds = 0
    total_jobs = 0
    @jobs.each do |job|
      wait_time_seconds = job.time_in_queue_seconds
      if wait_time_seconds
        total_waiting_time_seconds += wait_time_seconds
        total_jobs += 1
      end
    end
    return nil if total_jobs == 0
    average_time_seconds = total_waiting_time_seconds / total_jobs
    { 'job_count' => total_jobs,
      'total_time' => time_readable(total_waiting_time_seconds),
      'mean_time' => time_readable(average_time_seconds) }
  end

  def running_time
    total_walltime_seconds = 0
    total_jobs = 0
    @jobs.each do |job|
      next unless job.ran?
      walltime_seconds = job.walltime_seconds
      if walltime_seconds
        total_walltime_seconds += walltime_seconds
        total_jobs += 1
      end
    end
    return nil if total_jobs == 0
    average_time_seconds = total_walltime_seconds / total_jobs
    { 'job_count' => total_jobs,
      'total_time' => time_readable(total_walltime_seconds),
      'mean_time' => time_readable(average_time_seconds) }
  end

  private

  def generic_frequency(key_name)
    return if @jobs.empty?
    frequency = {}
    @jobs.each do |job|
      key = yield(job)
      frequency[key] ||= 0
      frequency[key] += 1
    end
    return nil if frequency.empty?
    unsorted = frequency.collect do |key, value|
      { key_name => key,
        'job_count' => value }
    end
    unsorted.sort_by { |value| value['job_count'] }.reverse
  end

  def efficiency
    return if @jobs.empty?

    total_cpu_seconds = 0
    total_walltime_seconds = 0
    total_max_memory_bytes = 0
    total_memory_requested_bytes = 0
    total_jobs = 0
    @jobs.each do |job|
      next unless job.ran?
      next unless job.core_walltime_seconds > 0
      next unless job.memory_requested_bytes > 0

      total_jobs += 1
      total_walltime_seconds += job.core_walltime_seconds
      total_cpu_seconds += job.total_cpu_seconds
      total_memory_requested_bytes += job.memory_requested_bytes
      total_max_memory_bytes += job.max_memory_bytes
    end
    return if total_jobs == 0

    cpu_efficiency = total_cpu_seconds.to_f / total_walltime_seconds
    cpu_efficiency_percent = (100.0 * cpu_efficiency).round(3)
    memory_efficiency =
      total_max_memory_bytes.to_f / total_memory_requested_bytes
    memory_efficiency_percent = (100.0 * memory_efficiency).round(3)
    {
      'job_count' => total_jobs,
      'mean_cpu_efficiency_percent' => cpu_efficiency_percent,
      'mean_memory_efficiency_percent' => memory_efficiency_percent
    }
  end

end
