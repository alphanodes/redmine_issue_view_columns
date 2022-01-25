# frozen_string_literal: true

module IssueViewColumnsProjectSettingsTab
  def project_settings_tabs
    tabs = super

    if User.current.allowed_to?(:manage_issue_view_columns, @project) &&
       @project.module_enabled?(:issue_view_columns)
      tabs << { name: 'issue_view_columns',
                action: :issue_view_columns,
                partial: 'issue_view_columns/index',
                label: :issue_view_columns_settings }
    end

    tabs
  end

  ProjectsController.send :helper, IssueViewColumnsProjectSettingsTab
end
