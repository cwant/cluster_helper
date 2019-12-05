class ClusterHelper::ActiveJob < ClusterHelper::Job

  FIELDS = ClusterHelper::ActiveJobQuery::SQUEUE_FIELDS.keys

  attr_reader(*FIELDS)

  class << self
    [:user, :username, :account, :account_name].each do |method|
      define_method(method) do |*args|
        ClusterHelper::ActiveJobQuery.new.send(method, *args)
      end
    end

    def slurm_fields
      @slurm_fields ||= FIELDS
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
