require 'json'

module LikeAUser
  def accounts
    @accounts ||= ClusterHelper::Account.where(user: self)
  end

  def active_jobs
    @jobs ||= ClusterHelper::ActiveJob.where(user: self)
  end

  def finished_jobs
    @jobs ||= ClusterHelper::FinishedJob.where(user: self)
  end

  def to_h
    out = { username: username }
    out[:accounts] = @accounts if @accounts
    out[:jobs] = @jobs if @jobs
    out
  end

  def to_json(options = {})
    to_h.to_json(options)
  end
end
