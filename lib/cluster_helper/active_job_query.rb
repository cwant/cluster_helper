class ClusterHelper::ActiveJobQuery < ClusterHelper::JobQuery

  SQUEUE_FIELDS = {
    id: '%i',
    user: '%u',
    account: '%a',
    name: '%j',
    state: '%T',
    priority: '%Q',
    submit_time: '%V',
    start_time: '%S',
    memory_requested_bytes: '%m',
    number_of_cpus: '%C',
    number_of_nodes: '%D',
    walltime_requested_seconds: '%l'
  }.freeze

  QUERY_COMMAND = ("squeue -o '" +
                   SQUEUE_FIELDS.values.map { |f| '%' + f }.join('|') +
                   "' -h %<users_flag>s %<accounts_flag>s").freeze

  def query_command
    return @query_command if @query_command
    @query_command = format(QUERY_COMMAND,
                            users_flag: users_flag,
                            accounts_flag: accounts_flag)
  end

  def slurm_fields
    @slurm_fields ||= SQUEUE_FIELDS.keys
  end

  private

  def lines_to_jobs(lines)
    lines.map { |line| line_to_job(line) }
  end

  def line_to_job(line)
    hash = line_to_hash(line)
    hash = edit_hash_from_cache(hash)
    ClusterHelper::ActiveJob.new(hash)
  end

end
