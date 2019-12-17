module JobConsole::JobCommands
  include JobConsole::Exceptions
  include JobConsole::Constants

  def fetch_active_jobs
    query = ClusterHelper::ActiveJob
    query = query.user(user) unless accounts
    query = query.account(accounts) if accounts
    self.jobs = query.all
  end

  def process_job_command(*args)
    subcommand = args.first
    if subcommand && JOB_COMMANDS.include?(subcommand.downcase)
      # e.g., strip out unneccessary 'job'
      args = args[1..-1]
      args = [] if args.nil?
      subcommand = args.first
    end

    if INACTIVE_STATE_SUBCOMMANDS.include?(subcommand)
      return process_inactive_job_command(*args)
    end

    fetch_active_jobs unless jobs

    if SHOW_ALL_SUBCOMMANDS.include?(subcommand)
      return render('jobs' => jobs.map { |job| job.to_h.stringify_keys })
    end

    return perform_job_stats(*args) if STATS_SUBCOMMANDS.include?(subcommand)

    return render(count: jobs.count) if subcommand == 'count'

    if ACTIVE_STATE_SUBCOMMANDS.include?(subcommand)
      return process_job_state_command(*args)
    end

    if ACCOUNT_COMMANDS.include?(subcommand.downcase)
      self.accounts = jobs.map(&:account).uniq
      return process_account_command(*args[1..-1])
    end

    job = jobs.find { |j| j.id == subcommand }
    return render('job' => job.to_h.stringify_keys) if job
    raise UnknownJob, subcommand
  end

  def fetch_inactive_jobs
    query = ClusterHelper::InactiveJob
    query = query.user(user) unless accounts
    query = query.account(accounts) if accounts
    query = query.end_date(end_date) if end_date
    query = query.start_date(start_date) if start_date
    self.jobs = query.all
  end

  def process_inactive_job_command(*args)
    subcommand = args.first

    if jobs.nil?
      fetch_inactive_jobs
    else
      job = jobs.first
      fetch_inactive_jobs if job.nil? || job.active?
    end
    self.jobs = jobs.select(&:completed?) if subcommand == 'completed'

    process_job_command(*args[1..-1])
  end

  def process_job_state_command(*args)
    subcommand = args.first

    if subcommand == 'running'
      self.jobs = jobs.select(&:running?)
    elsif subcommand == 'pending'
      self.jobs = jobs.select(&:pending?)
    end
    process_job_command(*args[1..-1])
  end
end
