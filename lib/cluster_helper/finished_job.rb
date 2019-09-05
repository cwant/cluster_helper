require_relative 'concerns/instance_variables_to_h'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::FinishedJob < ClusterHelper::Job

  include InstanceVariablesToH

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

  class << self

    def slurm_fields
      @slurm_fields ||= SACCT_FIELDS.keys
    end

    def memory_to_bytes(str)
      m = str.match(/^[\d]*/)
      return 0 unless m
      value = m[0].to_i

      tail = str.gsub(/^[\d]*/, '')
      return value if tail.empty?
      return 1024 * value if tail[0].downcase == 'k'
      return (1024**2) * value  if tail[0].downcase == 'm'
      return (1024**3) * value  if tail[0].downcase == 'g'
      return (1024**4) * value  if tail[0].downcase == 't'
      value
    end

    def time_to_seconds(str)
      parts = str.split('.')
      str = parts[0]
      milli_str = parts.length > 1 ? parts[1] : nil
      milli = 0
      milli = "0.#{milli_str}".to_f if milli_str
      parts = str.split('-')
      days = 0
      hours = 0
      minutes = 0
      if parts.length > 1
        days = parts[0].to_i
        str = parts[1]
      else
        str = parts[0]
      end
      parts = str.split(':').reverse
      seconds = parts[0].to_i
      minutes = parts[1].to_i if parts.length > 1
      hours = parts[2].to_i if parts.length > 2

      days * 24 * 3600 + hours * 3600 + minutes * 60 + seconds + milli
    end

    private

    def user_jobs_command
      USER_JOBS_COMMAND.gsub('%<after>s',
                             (Date.today - 30).to_s)
    end

    def account_jobs_command
      ACCOUNT_JOBS_COMMAND.gsub('%<after>s',
                                (Date.today - 30).to_s)
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

    def line_to_hash(line)
      arr = line.strip.split('|')
      hash = {}
      slurm_fields.each_with_index do |key, i|
        value = arr[i]

        if value
          if [:memory_requested_bytes,
              :maximum_memory_used_bytes].include?(key)
            value = memory_to_bytes(value)
          elsif [:allocated_cpus,
                 :number_of_nodes,
                 :number_of_tasks].include?(key)
            value = value.to_i
          elsif [:submit_time,
                 :start_time,
                 :end_time].include?(key)
            value = DateTime.parse(value)
          elsif [:walltime_seconds,
                 :total_cpu_time_used_seconds].include?(key)
            value = time_to_seconds(value)
          end

        end
        hash[key] = value
      end

      hash
    end

    def hash_is_job?(hash)
      hash[:id] !~ /\./
    end

    def hash_to_job(hash, user_cache, account_cache)
      username = hash[:user]
      user = user_cache[username] ||
             ClusterHelper::User.new(username)
      user_cache[username] ||= user
      hash[:user] = user

      account_name = hash[:account]
      account = account_cache[account_name] ||
                ClusterHelper::Account.new(account_name)
      account_cache[account_name] ||= account
      hash[:account] = account

      new(hash)
    end

  end

  def add_steps(steps)
    @memory_efficiency = nil
    @cpu_efficiency = nil
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
    @memory_efficiency = (100.0 * max_memory_bytes) / memory_requested_bytes
    core_walltime_seconds = walltime_seconds * allocated_cpus
    @cpu_efficiency = (100.0 * total_cpu_seconds) / core_walltime_seconds
  end

end
