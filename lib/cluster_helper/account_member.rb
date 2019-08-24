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

  def to_h
    out = super
    out[:norm_shares] = norm_shares
    out[:effective_usage] = effective_usage
    out
  end

end
