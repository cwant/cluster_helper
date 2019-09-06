require 'time'
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
             :total_cpu_time_used_seconds].include?(key)
        value = time_to_seconds(value)
      end

      value
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

  def time_in_queue_seconds
    return nil unless submit_time
    start = start_time || Time.now

    start.to_time.to_i - submit_time.to_time.to_i
  end

  def time_in_queue
    time_readable(time_in_queue_seconds)
  end

  def format_events(key, value)
    if [:submit_time,
        :start_time,
        :end_time].include?(key)
      value = value.strftime('%FT%T') if value
    end
    [key, value]
  end

  def time_readable(total_seconds)
    return nil unless total_seconds

    int_seconds = total_seconds.to_i
    left_over = (total_seconds - int_seconds).round(3)
    seconds = int_seconds % 60
    seconds += left_over if left_over > 0.0
    minutes = (int_seconds / 60) % 60
    hours = (int_seconds / (60 * 60)) % 24
    days = int_seconds / (60 * 60 * 24)

    out = ''
    out += "#{days}d " if days > 0
    out += "#{hours}h " if days > 0 || hours > 0
    out += "#{minutes}m #{seconds}s"
    out
  end

  def memory_requested_megabytes
    (memory_requested_bytes / 1024.0**2).round(3)
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

  def request_to_h
    methods_to_h([:number_of_nodes,
                  :number_of_cpus,
                  :memory_requested_megabytes])
  end

end
