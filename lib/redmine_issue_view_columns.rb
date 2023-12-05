# frozen_string_literal: true

module RedmineIssueViewColumns
  VERSION = '2.0.3'

  include RedminePluginKit::PluginBase

  class << self
    private

    def setup
      # Patches
      loader.add_patch %w[Project]

      # include QueriesHelper in projects helper
      # Helper
      loader.add_helper [{ controller: 'Issues', helper: 'IssueViewColumnsIssues' },
                         { controller: 'Projects', helper: 'IssueViewColumnsProjects' }]

      # Apply patches and helper
      loader.apply!

      # Load view macros
      loader.load_view_hooks!
    end
  end
end
