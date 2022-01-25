# frozen_string_literal: true

module IssueViewColumnsProjectsHelper
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

  def build_query_for_project
    @selected_columns = IssueViewColumns.where(project_id: @project.id)
                                        .sort_by(&:order)
                                        .collect(&:ident)
    @selected_columns = ['#'] if @selected_columns.count.zero?
    @query = IssueQuery.new column_names: @selected_columns
    @query.project = @project
    @query
  end
end
