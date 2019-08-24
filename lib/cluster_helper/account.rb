class ClusterHelper::Account

  USER_ACCOUNTS_COMMAND =
    'sacctmgr show user %<user>s withassoc -P -n format=account,share'.freeze

  ACCOUNT_COMMAND = 'sshare -l -A %<account>s -a '\
                    '--format User,NormShares,EffectvUsage -n -P'.freeze

  attr_reader :name

  class << self

    def where(username: nil, user: nil)
      return [] if username.nil? && user.nil?
      username = user.username if username.nil?
      cmd = format(USER_ACCOUNTS_COMMAND, user: username)

      # TODO: handle errors
      lines = IO.popen(cmd).readlines
      lines.map { |line| line.strip.split('|') }
           .reject { |arr| arr[1] == '0' }
           .map(&:first)
           .map { |name| ClusterHelper::Account.new(name) }
    end

  end

  def initialize(name)
    @name = name
  end

  def members
    return @members if @members

    load_data
    @members
  end

  def effective_usage
    return @effective_usage if @effective_usage

    load_data
    @effective_usage
  end

  def norm_shares
    return @norm_shares if @norm_shares

    load_data
    @norm_shares
  end

  private

  def load_data
    data = account_data
    group_data = data.find { |h| h[:username].nil? || h[:username].empty? }
    if group_data
      @norm_shares = group_data[:norm_shares]
      @effective_usage = group_data[:effective_usage]
    end

    @members =
      data.select { |h| !h[:username].empty? && h[:norm_shares] > 0.0 }
          .map do |h|
        ClusterHelper::AccountMember.new(h[:username],
                                         self,
                                         norm_shares: h[:norm_shares],
                                         effective_usage: h[:effective_usage])
      end
  end

  def account_data
    cmd = format(ACCOUNT_COMMAND, account: @name)

    # TODO: handle errors
    lines = IO.popen(cmd).readlines
    lines.map { |line| line.strip.split('|') }
         .map do |arr|
      { username: arr[0],
        norm_shares: arr[1].to_f,
        effective_usage: arr[2].to_f }
    end
  end

end
