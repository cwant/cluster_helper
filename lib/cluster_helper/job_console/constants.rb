module ClusterHelper::JobConsole::Constants
  ACCOUNT_COMMANDS = ['account', 'accounts', 'a'].freeze
  JOB_COMMANDS = ['job', 'jobs', 'j'].freeze
  RELOAD_COMMANDS = ['reload', 'r'].freeze
  FORMAT_COMMANDS = ['format', 'f'].freeze
  QUIT_COMMANDS = ['quit', 'exit', 'q'].freeze
  HELP_COMMANDS = ['help', 'h', '?'].freeze
  USER_COMMANDS = ['user', 'u'].freeze
  SETTINGS_COMMANDS = ['settings', 's'].freeze
  START_DATE_COMMANDS = ['start_date', 'start', 'sd'].freeze
  END_DATE_COMMANDS = ['end_date', 'end', 'ed'].freeze

  COMMANDS = (ACCOUNT_COMMANDS +
              JOB_COMMANDS +
              RELOAD_COMMANDS +
              FORMAT_COMMANDS +
              QUIT_COMMANDS +
              HELP_COMMANDS +
              SETTINGS_COMMANDS +
              USER_COMMANDS +
              START_DATE_COMMANDS +
              END_DATE_COMMANDS).freeze

  NAME_SUBCOMMANDS = ['name', 'names', 'n'].freeze
  MEMBER_SUBCOMMANDS = ['member', 'members', 'm'].freeze

  SHOW_ALL_SUBCOMMANDS = ['all', nil].freeze

  ACTIVE_STATE_SUBCOMMANDS = ['pending',
                              'running'].freeze
  INACTIVE_STATE_SUBCOMMANDS = ['inactive',
                                'completed'].freeze
  STATE_SUBCOMMANDS = (ACTIVE_STATE_SUBCOMMANDS +
                       INACTIVE_STATE_SUBCOMMANDS).freeze
  COUNT_SUBCOMMANDS = ['count'].freeze

  ACCOUNT_SUBCOMMANDS = (NAME_SUBCOMMANDS +
                         MEMBER_SUBCOMMANDS).freeze

  STATS_SUBCOMMANDS = ['stats', 'stat', 'st', 'analytics'].freeze

  JOB_SUBCOMMANDS = (SHOW_ALL_SUBCOMMANDS +
                     STATE_SUBCOMMANDS +
                     COUNT_SUBCOMMANDS +
                     STATS_SUBCOMMANDS).freeze
  FORMAT_SUBCOMMANDS = ['json', 'yaml', 'compact_json'].freeze

  SUBCOMMANDS = (ACCOUNT_SUBCOMMANDS +
                 JOB_SUBCOMMANDS +
                 FORMAT_SUBCOMMANDS).freeze

  AUTOCOMPLETE = (COMMANDS + SUBCOMMANDS)
                 .select { |c| c && c.length > 2 }.uniq.freeze
end
