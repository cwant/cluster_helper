require 'optparse'
require 'yaml'
require 'json'

class ClusterHelper::BaseReportProgram

  class UnknownOption < StandardError; end
  class UnknownFormat < StandardError; end

  FORMATS = [:yaml, :json, :compact_json].freeze
  DEFAULT_FORMAT = :yaml

  def self.config_options
    @config_options ||= []
  end

  def self.config_option(option)
    config_options << :"options_#{option}"
  end

  def self.default_format(format = nil)
    if format.nil?
      @default_format ||= DEFAULT_FORMAT
      return @default_format
    end
    raise UnknownFormat unless FORMATS.include?(format)

    @default_format = format
  end

  def use_format(format = nil)
    format ||= self.class.default_format
    format = format.to_sym
    if FORMATS.include?(format)
      @options[:format] = format
      return
    end
    raise UnknownFormat, format.to_s
  end

  def options_json(opts)
    opts.on('-J', '--json', 'Output pretty JSON') do
      use_format(:json)
    end
  end

  def options_compact_json(opts)
    opts.on('-C', '--compact-json', 'Output compact JSON') do
      use_format(:compact_json)
    end
  end

  def options_yaml(opts)
    opts.on('-Y', '--yaml', 'Output YAML') do
      use_format(:yaml)
    end
  end

  def options_user(opts)
    opts.on('-u', '--user USER', 'User to consider') do |v|
      @options[:user] = v
    end
  end

  def process_options
    @options = { format: self.class.default_format }

    program = $PROGRAM_NAME.split('/').last

    OptionParser.new do |opts|
      opts.banner = "Usage: #{program} [options]"

      self.class.config_options.each { |method| send(method, opts) }
    end.parse!
  end

  def user(username = nil)
    @user ||= ClusterHelper::User.new(username || @options[:user])
  end

  def run
    process_options
    main
  end

  def apply_format(output)
    format = @options[:format] || self.class.default_format
    return JSON.pretty_generate(output) if format == :json
    return output.to_json if format == :compact_json
    return output.to_yaml if format == :yaml
    output
  end

  def pager_command
    "less -P '(space=page down, q=quit):' -FX"
  end

  def render(output)
    # Code mostly borrowed from pager in hirb gem
    unless pager_command
      STDOUT.puts apply_format(output)
      return
    end

    pager = IO.popen(pager_command, 'w')
    begin
      save_stdout = STDOUT.clone
      STDOUT.reopen(pager)
      STDOUT.puts apply_format(output)
    rescue Errno::EPIPE # rubocop:disable  Lint/HandleExceptions
    ensure
      STDOUT.reopen(save_stdout)
      save_stdout.close
      pager.close
    end
  end

  def format
    @options[:format]
  end

end
