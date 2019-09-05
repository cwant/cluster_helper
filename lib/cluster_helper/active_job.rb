require_relative 'concerns/instance_variables_to_h'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::ActiveJob < ClusterHelper::Job

  include InstanceVariablesToH

  SQUEUE_FIELDS = {
    id: '%i',
    user: '%u',
    account: '%a',
    name: '%j',
    state: '%T',
    priority: '%Q',
    submit_time: '%V',
    start_time: '%S'
  }.freeze
  USER_JOBS_COMMAND = ("squeue -o '" +
                       SQUEUE_FIELDS.values.map { |f| '%' + f }.join('|') +
                       "' -h -u %<user>s").freeze
  ACCOUNT_JOBS_COMMAND = ("squeue -o '" +
                          SQUEUE_FIELDS.values.map { |f| '%' + f }.join('|') +
                          "' -h -A %<account>s").freeze

  attr_reader :id, :priority, :state, :user, :account, :name
  attr_reader :submit_time, :start_time

  class << self

    def slurm_fields
      @slurm_fields ||= SQUEUE_FIELDS.keys
    end

    private

    def user_jobs_command
      USER_JOBS_COMMAND
    end

    def account_jobs_command
      ACCOUNT_JOBS_COMMAND
    end

    def lines_to_jobs(lines, user_cache, account_cache)
      lines.map { |line| line_to_job(line, user_cache, account_cache) }
    end

    def line_to_job(line, user_cache, account_cache)
      out = {}
      arr = line.strip.split('|')
      slurm_fields.each_with_index do |key, i|
        value = arr[i]
        if key == :user
          user = user_cache[value] ||
                 ClusterHelper::User.new(value)
          user_cache[value] ||= user
          out[:user] = user
        elsif key == :account
          account = account_cache[value] ||
                    ClusterHelper::Account.new(value)
          account_cache[value] ||= account
          out[:account] = account
        else
          out[key] = value
        end
      end
      new(out)
    end
  end

end
