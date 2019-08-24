class ClusterHelper::Job

  SQUEUE_FIELDS = [
    { code: '%Q',
      name: :priority }.freeze,
    { code: '%i',
      name: :id }.freeze,
    { code: '%a',
      name: :account }.freeze,
    { code: '%j',
      name: :name }.freeze,
    { code: '%T',
      name: :state }.freeze
  ].freeze
  USER_JOBS_COMMAND = ("squeue -o '" +
                       SQUEUE_FIELDS.map { |f| '%' + f[:code] }.join('|') +
                       "' -h -u %<user>s").freeze
  attr_reader :id, :priority, :state, :user, :account, :name

  class << self

    def where(username: nil, user: nil)
      return [] if username.nil? && user.nil?
      username = user.username if username.nil?
      user ||= ClusterHelper::User.new(username)
      cmd = format(USER_JOBS_COMMAND, user: username)

      accounts_cache = {}
      # TODO: handle errors
      lines = IO.popen(cmd).readlines

      lines.map { |line| line_to_job(line, user, accounts_cache) }
    end

    private

    def line_to_job(line, user, accounts_cache)
      arr = line.strip.split('|')
      out = { user: user }
      id = nil
      SQUEUE_FIELDS.each_with_index do |f, i|
        if f[:name] == :id
          id = arr[i]
        elsif f[:name] == :account
          account = accounts_cache[arr[i]] ||
                    ClusterHelper::Account.new(arr[i])
          accounts_cache[arr[i]] ||= account
          out[:account] = account
        else
          out[f[:name]] = arr[i]
        end
      end
      new(id, **out)
    end

  end

  def initialize(id, priority: nil,
                 name: nil, account: nil,
                 user: nil, state: nil)
    @id = id
    @priority = priority
    @name = name
    @account = account
    @state = state
    @user = user
  end

  def to_h
    { id: id,
      priority: priority,
      name: name,
      state: state,
      user: user }
  end

  def to_json(options = {})
    to_h.to_json(options)
  end

end
