module LikeAUser

  ACCOUNTS_COMMAND =
    'sacctmgr show user %<user>s withassoc -P -n format=account,share'.freeze

  def accounts
    return @accounts if @accounts
    cmd = format(ACCOUNTS_COMMAND, user: username)

    # TODO: handle errors
    lines = IO.popen(cmd).readlines
    names = lines.map { |line| line.strip.split('|') }
                 .reject { |arr| arr[1] == '0' }
                 .map(&:first)
    # TODO: update syntax for Ruby >= 2.1
    @accounts = Hash[names.map do |name|
                       [name, ClusterHelper::Account.new(name)]
                     end]
  end

  def account_names
    @account_names ||= accounts.keys
  end

end
