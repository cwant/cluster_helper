module ClusterHelper::JobConsole::Input
  include ClusterHelper::JobConsole::Exceptions
  include ClusterHelper::JobConsole::Constants

  def input_to_commands(input)
    input.strip.split(';').map { |i| sanitize_input(i) }
  end

  def sanitize_input(input)
    parts = input.split(' ')
    method = parts[0].strip.downcase

    if JOB_COMMANDS.include?(method)
      method = 'job_command'
    elsif ACCOUNT_COMMANDS.include?(method)
      method = 'account_command'
    elsif RELOAD_COMMANDS.include?(method)
      method = 'reload'
    elsif HELP_COMMANDS.include?(method)
      method = 'help'
    elsif FORMAT_COMMANDS.include?(method)
      method = 'use_format'
    elsif USER_COMMANDS.include?(method)
      method = 'switch_user'
    elsif START_DATE_COMMANDS.include?(method)
      method = 'handle_start_date'
    elsif END_DATE_COMMANDS.include?(method)
      method = 'handle_end_date'
    elsif SETTINGS_COMMANDS.include?(method)
      method = 'settings'
    elsif QUIT_COMMANDS.include?(method)
      return nil
    elsif JOB_SUBCOMMANDS.include?(method)
      parts = ['job'] + parts
      method = 'job_command'
    elsif ACCOUNT_SUBCOMMANDS.include?(method)
      parts = ['account'] + parts
      method = 'account_command'
    elsif FORMAT_SUBCOMMANDS.include?(method)
      parts = ['format'] + parts
      method = 'use_format'
    else
      raise UnknownCommand, method
    end

    args = parts[1..-1].map { |value| "'#{value}'" }

    "#{method} #{args.join(', ')}"
  end
end
