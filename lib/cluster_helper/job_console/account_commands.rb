module ClusterHelper::JobConsole::AccountCommands
  include ClusterHelper::JobConsole::Exceptions
  include ClusterHelper::JobConsole::Constants

  def process_account_command(*args)
    self.accounts ||= user.accounts

    subcommand = args.first

    if ['name', 'names'].include?(subcommand)
      return render('accounts' => accounts.map(&:name))
    end

    if ['all', nil].include?(subcommand)
      return render('accounts' => accounts.map { |a| a.to_h.stringify_keys })
    end

    if subcommand == 'members'
      return render('accounts' =>
                    accounts.map do |account|
                      { 'name' => account.name,
                        'members' => account.members.map(&:username) }
                    end)
    end

    if INACTIVE_STATE_SUBCOMMANDS.include?(subcommand.downcase)
      self.jobs = ClusterHelper::InactiveJob.account(accounts).all
      return process_inactive_job_command(*args[1..-1])
    end

    if JOB_COMMANDS.include?(subcommand.downcase)
      self.jobs = ClusterHelper::ActiveJob.account(accounts).all
      return process_job_command(*args[1..-1])
    end

    self.accounts = accounts.select { |j| j.name.start_with?(subcommand) }
    return process_account_command(*args[1..-1]) if accounts.any?

    raise UnknownAccount, subcommand
  end
end
