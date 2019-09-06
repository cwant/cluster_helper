class ClusterHelper::FinishedJob < ClusterHelper::Job

  SACCT_FIELDS = {
    id: 'JobID',
    user: 'User',
    account: 'Account',
    name: 'JobName',
    state: 'State',
    submit_time: 'Submit',
    start_time: 'Start',
    end_time: 'End',
    memory_requested_bytes: 'REQMEM',
    maximum_memory_used_bytes: 'MaxRSS',
    exit_code: 'ExitCode',
    total_cpu_time_used_seconds: 'TotalCPU',
    walltime_seconds: 'Elapsed',
    allocated_cpus: 'AllocCPUS',
    number_of_nodes: 'NNodes',
    number_of_tasks: 'NTasks'
  }.freeze

  USER_JOBS_COMMAND = ('sacct -u %<user>s -P -n '\
                       '-S %<after>s --format ' +
                       SACCT_FIELDS.values.join(',')).freeze
  ACCOUNT_JOBS_COMMAND = ('sacct -A %<account>s -P -n '\
                          '-S %<after>s --format' +
                          SACCT_FIELDS.values.join(',')).freeze

  attr_reader(*SACCT_FIELDS.keys)
  attr_reader :memory_efficiency, :cpu_efficiency
  attr_reader :core_walltime_seconds

  alias number_of_cpus allocated_cpus

  class << self

    def slurm_fields
      @slurm_fields ||= SACCT_FIELDS.keys
    end

    private

    def user_jobs_command(options = {})
      days_ago = options[:days_ago] || 30
      after = (Date.today - days_ago).to_s
      format(USER_JOBS_COMMAND, options.merge(after: after))
    end

    def account_jobs_command(options = {})
      days_ago = options[:days_ago] || 30
      after = (Date.today - days_ago).to_s
      format(ACCOUNT_JOBS_COMMAND, options.merge(after: after))
    end

    def lines_to_jobs(lines, user_cache, account_cache)
      steps_by_id = {}
      jobs_by_id = {}

      lines.each do |line|
        hash = line_to_hash(line)
        if hash_is_job?(hash)
          job = hash_to_job(hash, user_cache, account_cache)
          jobs_by_id[job.id] = job
        else
          id = hash[:id].gsub(/\..*$/, '')
          steps_by_id[id] ||= []
          steps_by_id[id] << hash
        end
      end

      steps_by_id.each do |id, steps|
        job = jobs_by_id[id]
        job.add_steps(steps) if job
      end

      jobs_by_id.values
    end

    def hash_is_job?(hash)
      hash[:id] !~ /\./
    end

  end

  def add_steps(steps)
    @memory_efficiency_percent = nil
    @cpu_efficiency_percent = nil
    max_memory_bytes = 0
    total_cpu_seconds = 0
    @number_of_tasks = 0
    steps.each do |step|
      total_cpu_seconds += step[:total_cpu_time_used_seconds]
      bytes_used = step[:maximum_memory_used_bytes]
      if bytes_used > max_memory_bytes
        max_memory_bytes = bytes_used
        @number_of_tasks = step[:number_of_tasks]
      end
    end
    max_memory_bytes *= @number_of_tasks
    @maximum_memory_used_bytes = max_memory_bytes
    @memory_efficiency = max_memory_bytes.to_f / memory_requested_bytes
    @core_walltime_seconds = walltime_seconds * allocated_cpus
    @cpu_efficiency = total_cpu_seconds.to_f / @core_walltime_seconds
  end

  def maximum_memory_used_megabytes
    (maximum_memory_used_bytes / 1024.0**2).round(3)
  end

  def total_cpu_time_used
    time_readable(total_cpu_time_used_seconds)
  end

  def walltime
    time_readable(walltime_seconds)
  end

  def core_walltime
    time_readable(core_walltime_seconds)
  end

  def cpu_efficiency_percent
    return nil unless cpu_efficiency
    (100.0 * cpu_efficiency).round(3)
  end

  def memory_efficiency_percent
    return nil unless memory_efficiency
    (100.0 * memory_efficiency).round(3)
  end

  def to_h
    out = basic_fields_to_h

    out[:exit_code] = exit_code

    out[:request] = request_to_h
    out[:events] = events_to_h
    out[:memory] = memory_to_h
    out[:cpu] = cpu_to_h

    out
  end

  def active?
    false
  end

  def finished?
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
