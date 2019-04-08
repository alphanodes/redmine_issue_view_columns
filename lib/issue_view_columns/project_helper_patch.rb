module IssueViewColumnsProjectSettingsTab
  def project_settings_tabs
    super.tap do |tabs|
      tabs << {
        name: "issue_view_columns",
        action: :issue_view_columns,
        partial: "issue_view_columns/index",
        label: :issue_view_columns_settings,
      } if User.current.allowed_to?(:manage_issue_view_columns, @project) &&
           @project.module_enabled?(:issue_view_columns)
    end
  end

  ProjectsController.send :helper, IssueViewColumnsProjectSettingsTab
end
