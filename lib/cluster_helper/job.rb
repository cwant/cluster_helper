require_relative 'concerns/instance_variables_to_h'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::Job

  include InstanceVariablesToH

  class << self

    def where(options = {})
      return where_user(username: options[:username]) if options.key?(:username)
      return where_user(user: options[:user]) if options.key?(:user)
      if options.key?(:account_name)
        return where_account(account_name: options[:account_name])
      end
      return where_account(account: options[:account]) if options.key?(:account)
      []
    end

    private

    def where_user(username: nil, user: nil)
      return [] if username.nil? && user.nil?
      username = user.username if username.nil?
      user ||= ClusterHelper::User.new(username)
      cmd = format(user_jobs_command, user: username)

      account_cache = {}
      user_cache = { user.username => user }
      # TODO: handle errors
      lines = IO.popen(cmd).readlines

      lines_to_jobs(lines, user_cache, account_cache)
    end

    def where_account(account_name: nil, account: nil)
      return [] if account_name.nil? && account.nil?
      account_name = account.name if account_name.nil?
      account ||= ClusterHelper::Account.new(account_name)
      cmd = format(account_jobs_command, account: account_name)

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
