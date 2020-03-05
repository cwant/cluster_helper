require 'time'
require_relative 'concerns/methods_to_h'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::JobQuery

  include MethodsToH

  USERS_FLAG = '-u %<users>s'.freeze
  ACCOUNTS_FLAG = '-A %<accounts>s'.freeze

  def initialize(payload = nil)
    @payload = init_payload(payload)
    @user_cache = {}
    @account_cache = {}
    @errors = []

    @query_command = nil
    @all = nil
  end

  def init_payload(payload)
    out = payload || {}
    out[:users] ||= []
    out[:accounts] ||= []
    out
  end

  def user(users)
    Array(users).each do |user|
      if user.is_a?(String)
        username = user
        @user_cache[username] ||= ClusterHelper::User.new(username)
        @payload[:users] << @user_cache[username]
      else
        @user_cache[user.username] ||= user
        @payload[:users] << user
      end
    end
    self
  end

  def account(accounts)
    Array(accounts).each do |account|
      if account.is_a?(String)
        account_name = account
        @account_cache[account_name] ||=
          ClusterHelper::Account.new(account_name)
        @payload[:accounts] << @account_cache[account_name]
      else
        @account_cache[account.name] ||= account
        @payload[:accounts] << account
      end
    end
    self
  end

  def execute
    return nil unless query_command && @errors.empty?
    lines = IO.popen(query_command).readlines
    lines_to_jobs(lines)
  end

  def valid?
    true
  end

  def all
    @all ||= execute
  end

  private

  def users_flag
    if @payload[:users].any?
      users = @payload[:users].map(&:username).join(',')
      format(USERS_FLAG, users: users)
    elsif @payload[:accounts].any?
      users = @payload[:accounts].map(&:members).flatten
                                 .map(&:username).uniq.join(',')
      format(USERS_FLAG, users: users)
    else
      ''
    end
  end

  def accounts_flag
    if @payload[:accounts].any?
      accounts = @payload[:accounts].map(&:name).join(',')
      format(ACCOUNTS_FLAG, accounts: accounts)
    else
      ''
    end
  end

  def line_to_hash(line)
    arr = line.strip.split('|')
    hash = {}
    slurm_fields.each_with_index do |key, i|
      hash[key] = process_value_by_key(arr[i], key)
    end

    hash
  end

  def edit_hash_from_cache(hash)
    username = hash[:user]
    user = @user_cache[username] ||
           ClusterHelper::User.new(username)
    @user_cache[username] ||= user
    hash[:user] = user

    account_name = hash[:account]
    account = @account_cache[account_name] ||
              ClusterHelper::Account.new(account_name)
    @account_cache[account_name] ||= account
    hash[:account] = account
    hash
  end

  def to_datetime(value)
    return nil if ['Unknown', 'N/A'].include?(value)
    Time.parse(value).to_datetime
  end

  def process_value_by_key(value, key)
    return nil unless value

    if [:memory_requested_bytes,
        :maximum_memory_used_bytes].include?(key)
      value = memory_to_bytes(value)
    elsif [:number_of_cpus,
           :allocated_cpus,
           :number_of_nodes,
           :number_of_tasks].include?(key)
      value = value.to_i
    elsif [:submit_time,
           :start_time,
           :end_time].include?(key)
      value = to_datetime(value)
    elsif [:walltime_seconds,
           :total_cpu_time_used_seconds,
           :walltime_requested_seconds].include?(key)
      value = time_to_seconds(value)
    elsif key == :nodes
      value = parse_node_list(value)
    end

    value
  end

  def parse_node_list(str)
    return nil if str.nil? || str.empty?
    return nil if str == 'None assigned'
    if str.include?(',')
      if str.include?('[')
        m = str.match(/(^.*)\[(.*)\]/)
        return nil unless m
        prefix = m[1]
        suffixes = m[2].split(',')
        suffixes.map { |suffix| prefix + suffix }
      else
        str.split(',')
      end
    else
      [str]
    end
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
    return nil if str.nil? || str.empty?
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

end
