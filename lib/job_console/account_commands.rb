module JobConsole::AccountCommands
  include JobConsole::Exceptions
  include JobConsole::Constants
  include JobConsole::JobCommands

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
      self.jobs = fetch_inactive_jobs
      return process_inactive_job_command(*args)
    end

    if JOB_COMMANDS.include?(subcommand.downcase)
      self.jobs = fetch_active_jobs
      return process_job_command(*args)
    end

    self.accounts = accounts.select { |j| j.name.start_with?(subcommand) }
    return process_account_command(*args[1..-1]) if accounts.any?

    raise UnknownAccount, subcommand
  end
end
