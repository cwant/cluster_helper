require_relative 'concerns/instance_variables_to_h'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::Job

  include InstanceVariablesToH

  SQUEUE_FIELDS = [
    { code: '%i',
      name: :id }.freeze,
    { code: '%u',
      name: :user }.freeze,
    { code: '%a',
      name: :account }.freeze,
    { code: '%j',
      name: :name }.freeze,
    { code: '%T',
      name: :state }.freeze,
    { code: '%Q',
      name: :priority }.freeze,
    { code: '%V',
      name: :submit_time }.freeze,
    { code: '%S',
      name: :start_time }.freeze
  ].freeze
  USER_JOBS_COMMAND = ("squeue -o '" +
                       SQUEUE_FIELDS.map { |f| '%' + f[:code] }.join('|') +
                       "' -h -u %<user>s").freeze
  ACCOUNT_JOBS_COMMAND = ("squeue -o '" +
                          SQUEUE_FIELDS.map { |f| '%' + f[:code] }.join('|') +
                          "' -h -A %<account>s").freeze
  attr_reader :id, :priority, :state, :user, :account, :name
  attr_reader :submit_time, :start_time

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
      cmd = format(USER_JOBS_COMMAND, user: username)

      accounts_cache = {}
      # TODO: handle errors
      lines = IO.popen(cmd).readlines

      lines.map { |line| user_line_to_job(line, user, accounts_cache) }
    end

    def where_account(account_name: nil, account: nil)
      return [] if account_name.nil? && account.nil?
      account_name = account.name if account_name.nil?
      account ||= ClusterHelper::Account.new(account_name)
      cmd = format(ACCOUNT_JOBS_COMMAND, account: account_name)

      user_cache = {}
      # TODO: handle errors
      lines = IO.popen(cmd).readlines

      lines.map { |line| account_line_to_job(line, account, user_cache) }
    end

    def user_line_to_job(line, user, accounts_cache)
      arr = line.strip.split('|')
      out = { user: user }
      SQUEUE_FIELDS.each_with_index do |f, i|
        next if f[:name] == :user
        if f[:name] == :account
          account = accounts_cache[arr[i]] ||
                    ClusterHelper::Account.new(arr[i])
          accounts_cache[arr[i]] ||= account
          out[:account] = account
        else
          out[f[:name]] = arr[i]
        end
      end
      new(out)
    end

    def account_line_to_job(line, account, user_cache)
      arr = line.strip.split('|')
      out = { account: account }
      SQUEUE_FIELDS.each_with_index do |f, i|
        next if f[:name] == :account
        if f[:name] == :user
          user = user_cache[arr[i]] ||
                 ClusterHelper::User.new(arr[i])
          user_cache[arr[i]] ||= user
          out[:user] = user
        else
          out[f[:name]] = arr[i]
        end
      end
      new(out)
    end

  end

  def initialize(options = {})
    allowed_options = (SQUEUE_FIELDS.map { |h| h[:name] }) + [:user]
    options.each do |key, value|
      raise ArgumentError, 'Unknown Option' unless allowed_options.include?(key)
      instance_variable_set(:"@#{key}", value)
    end
    raise ArgumentError, 'No jobid' if @id.nil?
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

end
