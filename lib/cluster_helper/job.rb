require_relative 'concerns/methods_to_h'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::Job

  include MethodsToH

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

    def line_to_hash(line)
      arr = line.strip.split('|')
      hash = {}
      slurm_fields.each_with_index do |key, i|
        hash[key] = process_value_by_key(arr[i], key)
      end

      hash
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

    def to_datetime(value)
      return nil if ['Unknown', 'N/A'].include?(value)
      DateTime.parse(value)
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

  def completed?
    state == 'COMPLETED'
  end

  def initialize(options = {})
    allowed_options = self.class.slurm_fields + [:user]
    options.each do |key, value|
      raise ArgumentError, 'Unknown Option' unless allowed_options.include?(key)
      instance_variable_set(:"@#{key}", value)
    end
    raise ArgumentError, 'No jobid' if @id.nil?
  end

  private

  def basic_fields_to_h
    methods_to_h([:id,
                  :user,
                  :account,
                  :name,
                  :state]) do |key, value|
      if key == :user
        [key, value.username]
      elsif key == :account
        [key, value.name]
      else
        [key, value]
      end
    end
  end

end
