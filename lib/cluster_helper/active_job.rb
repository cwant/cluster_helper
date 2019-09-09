class ClusterHelper::ActiveJob < ClusterHelper::Job

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
    number_of_nodes: '%D'
  }.freeze

  USER_JOBS_COMMAND = ("squeue -o '" +
                       SQUEUE_FIELDS.values.map { |f| '%' + f }.join('|') +
                       "' -h -u %<user>s").freeze
  ACCOUNT_JOBS_COMMAND = ("squeue -o '" +
                          SQUEUE_FIELDS.values.map { |f| '%' + f }.join('|') +
                          "' -h -A %<account>s").freeze

  attr_reader(*SQUEUE_FIELDS.keys)

  class << self

    def slurm_fields
      @slurm_fields ||= SQUEUE_FIELDS.keys
    end

    private

    def user_jobs_command(options = {})
      format(USER_JOBS_COMMAND, options)
    end

    def account_jobs_command(options = {})
      format(ACCOUNT_JOBS_COMMAND, options)
    end

    def lines_to_jobs(lines, user_cache, account_cache)
      lines.map { |line| line_to_job(line, user_cache, account_cache) }
    end

    def line_to_job(line, user_cache, account_cache)
      hash = line_to_hash(line)
      hash_to_job(hash, user_cache, account_cache)
    end
  end

  def to_h
    out = basic_fields_to_h
    out[:priority] = priority
    out[:request] = request_to_h
    out[:events] = methods_to_h([:submit_time,
                                 :start_time,
                                 :time_in_queue]) do |key, value|
      format_events(key, value)
    end
    out
  end

  def active?
    true
  end

  def inactive?
    false
  end
end
