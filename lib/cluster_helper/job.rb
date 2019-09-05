require_relative 'concerns/instance_variables_to_h'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::Job

  include InstanceVariablesToH

  class << self

    def where(options = {})
      if options.key?(:username) || options.key?(:user)
        return where_user(options)
      end
      if options.key?(:account_name) || options.key?(:account)
        return where_account(options)
      end
      []
    end

    private

    def where_user(options = {})
      username = options[:username]
      user = options[:user]
      return [] if username.nil? && user.nil?
      username = user.username if username.nil?
      user ||= ClusterHelper::User.new(username)
      cmd = user_jobs_command(options.merge(user: username))

      account_cache = {}
      user_cache = { user.username => user }
      # TODO: handle errors
      lines = IO.popen(cmd).readlines

      lines_to_jobs(lines, user_cache, account_cache)
    end

    def where_account(options = {})
      account_name = options[:account_name]
      account = options[:account]
      return [] if account_name.nil? && account.nil?
      account_name = account.name if account_name.nil?
      account ||= ClusterHelper::Account.new(account_name)
      cmd = account_jobs_command(options.merge(account: account_name))

      user_cache = {}
      account_cache = { account.name => account }
      # TODO: handle errors
      lines = IO.popen(cmd).readlines

      lines_to_jobs(lines, user_cache, account_cache)
    end
  end

  def to_h
    instance_variables_to_h do |key, value|
      if key == :user
        [key, value.username]
      elsif key == :account
        [key, value.name]
      else
        [key, value]
      end
    end
  end

  def to_json(options = {})
    to_h.to_json(options)
  end

  def to_yaml(options = {})
    to_h.stringify_keys.to_yaml(options)
  end

  def running?
    state == 'RUNNING'
  end

  def pending?
    state == 'PENDING'
  end

  def initialize(options = {})
    allowed_options = self.class.slurm_fields + [:user]
    options.each do |key, value|
      raise ArgumentError, 'Unknown Option' unless allowed_options.include?(key)
      instance_variable_set(:"@#{key}", value)
    end
    raise ArgumentError, 'No jobid' if @id.nil?
  end

end
