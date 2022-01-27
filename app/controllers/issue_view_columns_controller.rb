# frozen_string_literal: true

class IssueViewColumnsController < ApplicationController
  include QueriesHelper
  include IssueViewColumnsProjectsHelper
  before_action :find_project_by_project_id
  before_action :build_query_for_project

  def index
    @query
  end

  # refactor update, it's not good to do save like this
  def update
    update_selected_columns = params[:c] || []
    IssueViewColumns.where(project_id: params[:project_id]).delete_all
    order = 0
    first_cols = %w[tracker subject]
    update_selected_columns.each do |col|
      # tracker and subject are always included in the first column
      next if first_cols.include? col

      c = IssueViewColumns.new
      order += 1
      c.project_id = params[:project_id]
      c.ident = col
      c.order = order
      c.save
    end
    redirect_to :back, notice: l(:label_issue_columns_created_sucessfully)
  end
end
