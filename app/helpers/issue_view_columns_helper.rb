module IssueViewColumnsHelper
  include QueriesHelper

  def build_query_for_project
    @selected_columns = IssueViewColumns.all.select { |c| c.project_id == @project.id }.sort_by { |o| o.order }.collect { |f| f.ident }
    @selected_columns = ["#"] unless @selected_columns.count > 0
    @query = IssueQuery.new(column_names: @selected_columns)
    @query.project = @project
    @query
  end
end
