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
    number_of_tasks: 'NTasks'
  }.freeze

  QUERY_COMMAND = ('sacct %<users_flag>s %<accounts_flag>s -P -n '\
                   '%<after_flag>s %<before_flag>s --format ' +
                   SACCT_FIELDS.values.join(',')).freeze

  AFTER_FLAG = '-S %<after>s'
  BEFORE_FLAG = '-E %<before>s'

  def initialize
    super

    @before = nil
    @after = nil
  end

  def before_days_ago(before = nil)
    @payload[:before_days_ago] = before
    self
  end

  def after_days_ago(after = nil)
    @payload[:after_days_ago] = after
    self
  end

  def after_flag
    days_ago = @payload[:after_days_ago] || DEFAULT_DAYS_AGO
    after = (Date.today - days_ago).to_s
    format(AFTER_FLAG, after: after)
  end

  def before_flag
    return '' unless @payload[:before_days_ago]
    before = (Date.today - @payload[:before_days_ago]).to_s
    format(BEFORE_FLAG, before: before)
  end

  def query_command
    return @query_command if @query_command
    @query_command = format(QUERY_COMMAND,
                            users_flag: users_flag,
                            accounts_flag: accounts_flag,
                            before_flag: before_flag,
                            after_flag: after_flag)
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
