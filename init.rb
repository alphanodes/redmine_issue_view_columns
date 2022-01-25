# frozen_string_literal: true

loader = RedminePluginKit::Loader.new plugin_id: 'redmine_issue_view_columns'

Redmine::Plugin.register :redmine_issue_view_columns do
  name 'Redmine Issue View Columns'
  author 'AlphaNodes GmbH'
  description 'Customize shown columns in subtasks and related issues on issue page'
  version RedmineIssueViewColumns::VERSION
  requires_redmine version_or_higher: '4.2.0'

  project_module :issue_view_columns do
    permission :manage_issue_view_columns, { issue_view_columns: :index }, { require: :member }
  end

  settings default: loader.default_settings, partial: 'settings/issue_view_columns_settings'
end

RedminePluginKit::Loader.persisting { loader.load_model_hooks! }
RedminePluginKit::Loader.to_prepare { RedmineIssueViewColumns.setup! } if Rails.version < '6.0'
