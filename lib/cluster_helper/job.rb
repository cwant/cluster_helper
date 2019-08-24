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
  attr_reader :id, :priority, :state, :user, :account

  def self.from_username(username, user: nil)
    cmd = format(USER_JOBS_COMMAND, user: username)

    # TODO: handle errors
    lines = IO.popen(cmd).readlines
    data = lines.map { |line| line.strip.split('|') }
                .map do |arr|
      out = { user: user || ClusterHelper::User(username) }
      id = nil
      SQUEUE_FIELDS.each_with_index do |f, i|
        if f[:name] == :id
          id = arr[i]
        elsif f[:name] == :account
          out[:account] = ClusterHelper::Account.new(arr[i])
        else
          out[f[:name]] = arr[i]
        end
      end
      [id, new(id, **out)]
    end
    Hash[data]
  end

  def self.from_user(user)
    from_username(user.username, user: user)
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

end
