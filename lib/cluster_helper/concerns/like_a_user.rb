module LikeAUser
  def accounts
    @accounts ||= ClusterHelper::Account.where(user: self)
  end

  def account_names
    @account_names ||= accounts.keys
  end

  def jobs
    @jobs ||= ClusterHelper::Job.where(user: self)
  end
end
