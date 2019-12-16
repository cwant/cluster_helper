#!/usr/bin/env ruby

require_relative '../cluster_helper/monkey_patch/hash_stringify_keys'
require 'readline'

class JobConsole::Main < ClusterHelper::BaseReportProgram
  include JobConsole::Exceptions
  include JobConsole::Constants
  include JobConsole::Input
  include JobConsole::JobCommands
  include JobConsole::AccountCommands

  config_option :user
  config_option :json
  config_option :compact_json
  config_option :yaml
  config_option :debug

  config_option :command

  attr_accessor :accounts
  attr_accessor :jobs
  attr_accessor :start_date
  attr_accessor :end_date

  private

  def options_command(opts)
    opts.on('-c', '--command COMMAND', 'Run command and exit') do |v|
      @options[:command] = v
    end
  end

  def print_help
    puts 'Some things to try (and try mixing):'
    puts '  jobs'
    puts '  jobs count'
    puts '  job 1112222333'
    puts '  jobs running (or pending, inactive, completed, etc)'
    puts '  jobs inactive (anything not pending or running)'
    puts '  jobs inactive stats'
    puts '  start_date 2001-01-01 (configure job search range)'
    puts '  end_date 2001-12-31'
    puts '  accounts'
    puts '  account members'
    puts '  account def-howdy (or just match start of account name)'
    puts '  account def-howdy jobs'
    puts '  account def jobs running'
    puts '  format json (default format yaml)'
    puts '  help'
    puts 'Press Ctrl-D to exit.'
  end
  alias help print_help

  def main
    return single_command(@options[:command]) if @options[:command]

    print_help
    command_loop
  end

  def single_command(input)
    bnd = binding()
    @input = input
    input_to_commands(input).each do |command|
      break unless command
      bnd.eval command
    end
  end

  def settings
    out = { user: user.username,
            format: format }
    out[:start_date] = start_date if start_date
    out[:end_date] = end_date if end_date
    out
  end

  def handle_settings
    render(settings: settings)
  end

  def command_loop
    comp = proc { |s| AUTOCOMPLETE.grep(/^#{Regexp.escape(s)}/) }

    Readline.completion_append_character = ' '
    Readline.completion_proc = comp

    bnd = binding()
    while (input = Readline.readline(prompt, true))
      @input = input
      begin
        input_to_commands(input).each do |command|
          return nil unless command
          bnd.eval command
        end
      rescue UnknownOption => e
        puts "Unknown option: #{e.message} (type 'help' for assistance)"
      rescue ClusterHelper::BaseReportProgram::UnknownFormat => e
        puts "Unknown format: #{e.message} (type 'help' for assistance)"
      rescue UnknownCommand => e
        puts "Unknown command: #{e.message} (type 'help' for assistance)"
      rescue UnknownAccount => e
        puts "Unknown account: #{e.message} (type 'help' for assistance)"
      rescue UnknownJob => e
        puts "Unknown job: #{e.message} (type 'help' for assistance)"
      rescue StandardError => e
        puts "Error (#{e.class}) (type 'help' for assistance)"
        puts e.message if @options[:debug]
        puts e.backtrace if @options[:debug]
      end
    end
    puts ''
  end

  def prompt
    "job_console(#{user.username})> "
  end

  def reset_jobs_accounts
    self.jobs = nil
    self.accounts = nil
  end

  def job_command(*args)
    reset_jobs_accounts
    process_job_command(*args)
  rescue UnknownOption
    # Subcommand not known? Assume it is an inactive job ID
    jobid = args.first
    job = user.inactive_jobs.find { |j| j.id == jobid }
    return render('job' => job.to_h.stringify_keys) if job
    raise UnknownJob, jobid
  end

  def account_command(*args)
    reset_jobs_accounts
    process_account_command(*args)
  end

  def switch_user(username = nil)
    @user = ClusterHelper::User.new(username || @options[:user])
  end

  def reload
    @user.reload
  end

  def handle_start_date(*args)
    self.start_date = get_date(*args)
  end

  def handle_end_date(*args)
    self.end_date = get_date(*args)
  end

  def get_date(*args)
    return nil unless args.first
    return args[1..-1].first if args.first.downcase == 'date'
    args.first
  end

  def perform_job_stats(*args)
    metadata = { excecuted_at: Time.now,
                 settings: settings,
                 input: @input }
    render('stats' => ClusterHelper::JobStatistics.new(jobs).to_h,
           'metadata' => metadata.stringify_keys)
  end

end
