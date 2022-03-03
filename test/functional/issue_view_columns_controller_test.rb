# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueViewColumnsControllerTest < RedmineIssueViewColumns::ControllerTest
  fixtures :users, :email_addresses, :roles,
           :enumerations,
           :projects, :projects_trackers, :enabled_modules,
           :members, :member_roles,
           :issues, :issue_statuses, :issue_categories, :issue_relations,
           :versions,
           :trackers,
           :workflows,
           :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :issue_view_columns

  include Redmine::I18n
  include CrudControllerBase

  def setup
    prepare_tests
    User.current = nil

    @user = users :users_001
    @user_without_permission = users :users_003
    @project = projects :projects_001

    @crud = { without_actions: %i[index create delete edit new show],
              show_params: { project_id: @project },
              show_assert_select: ['form.issue_view_columns'],
              update_params: { project_id: @project,
                               'selected_c[author]' => 'Author',
                               'selected_c[status]' => 'Status' },
              update_redirect_to: settings_project_path(@project, tab: 'issue_view_columns') }
  end
end
