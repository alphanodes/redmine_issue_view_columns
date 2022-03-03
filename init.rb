# frozen_string_literal: true

loader = RedminePluginKit::Loader.new plugin_id: 'redmine_issue_view_columns'

Redmine::Plugin.register :redmine_issue_view_columns do
  name 'Redmine Issue View Columns'
  author 'AlphaNodes GmbH'
  author_url 'https://alphanodes.com/'
  description 'Customize shown columns in subtasks and related issues on issue page'
  version RedmineIssueViewColumns::VERSION
  requires_redmine version_or_higher: '4.2.0'

  begin
    requires_redmine_plugin :additionals, version_or_higher: '3.0.4'
  rescue Redmine::PluginNotFound
    raise 'Please install additionals plugin (https://github.com/alphanodes/additionals)'
  end

  project_module :issue_view_columns do
    permission :manage_issue_view_columns, { projects: :settings, issue_view_columns: :update }, require: :member
  end

  settings default: loader.default_settings, partial: 'settings/issue_view_columns_settings'
end

RedminePluginKit::Loader.persisting { loader.load_model_hooks! }
RedminePluginKit::Loader.to_prepare { RedmineIssueViewColumns.setup! } if Rails.version < '6.0'
