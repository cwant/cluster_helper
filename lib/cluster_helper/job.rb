require 'time'
require_relative 'concerns/methods_to_h'
require_relative 'concerns/time_readable'
require_relative 'monkey_patch/hash_stringify_keys'

class ClusterHelper::Job

  include MethodsToH
  include TimeReadable

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

  def ran?
    # Only assume job ran if nodes were assigned
    return false if nodes.nil? || nodes.empty?
    true
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

  def walltime_requested
    time_readable(walltime_requested_seconds)
  end

  def format_events(key, value)
    if [:submit_time,
        :start_time,
        :end_time].include?(key)
      value = value.strftime('%FT%T') if value
    end
    [key, value]
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
                  :memory_requested_megabytes,
                  :walltime_requested])
  end

end
