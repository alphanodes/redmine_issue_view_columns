# frozen_string_literal: true

module IssueViewColumnsHelper
  include QueriesHelper

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
