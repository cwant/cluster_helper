class ClusterHelper::InactiveJobQuery < ClusterHelper::JobQuery

  DEFAULT_DAYS_AGO = 30

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
    number_of_tasks: 'NTasks',
    walltime_requested_seconds: 'TimeLimit',
    nodes: 'NodeList'
  }.freeze

  QUERY_COMMAND = ('sacct %<users_flag>s %<accounts_flag>s -P -n '\
                   '%<start_flag>s %<end_flag>s --format ' +
                   SACCT_FIELDS.values.join(',')).freeze

  START_FLAG = '-S %<start_date>s'.freeze
  END_FLAG = '-E %<end_date>s'.freeze

  def initialize
    super

    @before = nil
    @after = nil
  end

  def start_date(date = nil)
    @payload[:start_date] = date
    self
  end

  def end_date(date = nil)
    @payload[:end_date] = date
    self
  end

  def start_days_ago(days_ago = nil)
    @payload[:start_date] = days_ago_to_date(days_ago)
    self
  end

  def end_days_ago(days_ago = nil)
    @payload[:end_date] = days_ago_to_date(days_ago)
    self
  end

  def days_ago_to_date(days_ago = nil)
    return nil if days_ago.nil?
    (Date.today - days_ago).to_s
  end

  def start_flag
    start_date = @payload[:start_date] || days_ago_to_date(DEFAULT_DAYS_AGO)
    format(START_FLAG, start_date: start_date)
  end

  def end_flag
    return '' unless @payload[:end_date]
    format(END_FLAG, end_date: @payload[:end_date])
  end

  def query_command
    return @query_command if @query_command
    @query_command = format(QUERY_COMMAND,
                            users_flag: users_flag,
                            accounts_flag: accounts_flag,
                            start_flag: start_flag,
                            end_flag: end_flag)
  end

  def slurm_fields
    @slurm_fields ||= SACCT_FIELDS.keys
  end

  private

  def lines_to_jobs(lines)
    steps_by_id = {}
    jobs_by_id = {}

    lines.each do |line|
      hash = line_to_hash(line)
      if hash_is_job?(hash)
        hash = edit_hash_from_cache(hash)
        job = ClusterHelper::InactiveJob.new(hash)
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
