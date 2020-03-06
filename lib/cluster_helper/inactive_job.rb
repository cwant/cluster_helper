class ClusterHelper::InactiveJob < ClusterHelper::Job

  DEFAULT_DAYS_AGO = 30

  FIELDS = ClusterHelper::InactiveJobQuery::SACCT_FIELDS.keys

  attr_reader(*FIELDS)
  attr_reader :memory_efficiency, :cpu_efficiency
  attr_reader :core_walltime_seconds, :total_cpu_seconds
  attr_reader :max_memory_bytes

  alias number_of_cpus allocated_cpus

  class << self
    [:user, :username, :account, :account_name].each do |method|
      define_method(method) do |*args|
        ClusterHelper::InactiveJobQuery.new.send(method, *args)
      end
    end

    def slurm_fields
      @slurm_fields ||= FIELDS
    end
  end

  def add_steps(steps)
    @memory_efficiency_percent = nil
    @cpu_efficiency_percent = nil
    @max_memory_bytes = 0
    @total_cpu_seconds = 0
    @number_of_tasks = 0
    steps.each do |step|
      @total_cpu_seconds += step[:total_cpu_time_used_seconds] || 0
      bytes_used = step[:maximum_memory_used_bytes] || 0
      if bytes_used > max_memory_bytes
        @max_memory_bytes = bytes_used
        @number_of_tasks = step[:number_of_tasks]
      end
    end
    @max_memory_bytes *= @number_of_tasks
    @maximum_memory_used_bytes = max_memory_bytes
    @memory_efficiency = if memory_requested_bytes > 0
                           @max_memory_bytes.to_f / memory_requested_bytes
                         else
                           0
                         end
    @core_walltime_seconds = walltime_seconds * allocated_cpus
    @cpu_efficiency = if @core_walltime_seconds > 0
                        @total_cpu_seconds.to_f / @core_walltime_seconds
                      else
                        0
                      end
  end

  def maximum_memory_used_megabytes
    return nil unless ran?
    (maximum_memory_used_bytes / 1024.0**2).round(3)
  end

  def total_cpu_time_used
    return nil unless ran?
    time_readable(total_cpu_time_used_seconds)
  end

  def walltime
    return nil unless ran?
    time_readable(walltime_seconds)
  end

  def core_walltime
    return nil unless ran?
    time_readable(core_walltime_seconds)
  end

  def cpu_efficiency_percent
    return nil unless ran?
    return nil unless cpu_efficiency
    (100.0 * cpu_efficiency).round(3)
  end

  def memory_efficiency_percent
    return nil unless ran?
    return nil unless memory_efficiency
    (100.0 * memory_efficiency).round(3)
  end

  def to_h
    out = basic_fields_to_h

    out[:exit_code] = exit_code

    out[:request] = request_to_h
    out[:events] = events_to_h
    if ran?
      out[:memory] = memory_to_h
      out[:cpu] = cpu_to_h
      out[:nodes] = nodes
    end

    out
  end

  def active?
    false
  end

  def inactive?
    true
  end

  private

  def events_to_h
    methods_to_h([:submit_time,
                  :start_time,
                  :end_time,
                  :time_in_queue]) do |key, value|
      format_events(key, value)
    end
  end

  def memory_to_h
    methods_to_h([:memory_requested_megabytes,
                  :maximum_memory_used_megabytes,
                  :memory_efficiency_percent])
  end

  def cpu_to_h
    methods_to_h([:total_cpu_time_used,
                  :walltime,
                  :core_walltime,
                  :cpu_efficiency_percent])
  end

end
