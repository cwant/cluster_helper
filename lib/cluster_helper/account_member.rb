require_relative 'concerns/like_a_user'

class ClusterHelper::AccountMember

  include LikeAUser

  attr_reader :username, :account, :norm_shares, :effective_usage

  def initialize(username, account,
                 norm_shares: nil, effective_usage: nil)
    @username = username
    @account = account
    @norm_shares = norm_shares
    @effective_usage = effective_usage
  end
end