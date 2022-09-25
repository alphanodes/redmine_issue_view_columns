# frozen_string_literal: true

class IssueViewColumnsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :build_query_for_project

  include QueriesHelper
  include IssueViewColumnsProjectsHelper

  # refactor update, it's not good to do save like this
  def update
    update_selected_columns = params[:c] || []
    IssueViewColumn.where(project_id: @project).delete_all
    position = 0
    first_cols = %w[tracker subject]
    update_selected_columns.each do |col|
      # tracker and subject are always included in the first column
      next if first_cols.include? col

      position += 1
      c = IssueViewColumn.new project_id: @project.id,
                              name: col,
                              position: position
      c.save!
    end

    redirect_to settings_project_path(@project, tab: 'issue_view_columns'), notice: l(:label_issue_columns_created_sucessfully)
  end
end
