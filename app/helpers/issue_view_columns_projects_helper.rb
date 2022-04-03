# frozen_string_literal: true

module IssueViewColumnsProjectsHelper
  def project_settings_tabs
    tabs = super

    if User.current.allowed_to? :manage_issue_view_columns, @project
      tabs << { name: 'issue_view_columns',
                action: :issue_view_columns,
                partial: 'projects/settings/issue_view_columns',
                label: :issue_view_columns_settings }
    end

    tabs
  end

  def build_query_for_project
    @selected_columns = IssueViewColumn.where(project_id: @project).sorted.pluck(:name)
    @selected_columns = ['#'] if @selected_columns.count.zero?
    @query = IssueQuery.new column_names: @selected_columns
    @query.project = @project
    @query
  end
end
