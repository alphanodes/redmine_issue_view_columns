# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssuesControllerTest < RedmineIssueViewColumns::ControllerTest
  fixtures :users, :email_addresses, :roles,
           :enumerations,
           :projects, :projects_trackers, :enabled_modules,
           :members, :member_roles,
           :issues, :issue_statuses, :issue_categories, :issue_relations,
           :versions,
           :trackers,
           :workflows,
           :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries,
           :watchers, :journals, :journal_details,
           :queries, :issue_view_columns

  def setup
    prepare_tests

    @global_settings = { 'column_names' => %w[created_on updated_on] }
  end

  def test_show_author_column_for_related_issues_with_project_setting
    issue = issues :issues_002

    get :show, params: { id: issue.id }

    assert_response :success
    assert_select '#relations td.author'
  end

  def test_show_default_columns_for_related_issues_without_global_setting
    issue = issues :issues_004
    related_issue = Issue.generate! project_id: 2

    IssueRelation.create! issue_from: related_issue,
                          issue_to: issue,
                          relation_type: 'relates'

    @request.session[:user_id] = 1
    with_plugin_settings 'redmine_issue_view_columns', issue_list_defaults: {} do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select '#relations td.due_date'
    end
  end

  def test_show_custom_columns_for_related_issues_with_global_setting
    issue = issues :issues_004
    related_issue = Issue.generate! project_id: 2

    IssueRelation.create! issue_from: related_issue,
                          issue_to: issue,
                          relation_type: 'relates'

    @request.session[:user_id] = 1
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_list_defaults: @global_settings do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select '#relations td.created_on'
      assert_select '#relations td.updated_on'
    end
  end

  def test_show_author_column_for_subtasks_with_project_setting
    issue = issues :issues_002
    Issue.generate! project_id: 1, parent_issue_id: issue.id

    get :show, params: { id: issue.id }

    assert_response :success
    assert_select '#issue_tree td.author'
  end

  def test_show_default_columns_for_subtasks_without_global_setting
    issue = issues :issues_004
    Issue.generate! project_id: 2, parent_issue_id: issue.id

    @request.session[:user_id] = 1
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_list_defaults: {} do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select '#issue_tree td.due_date'
    end
  end

  def test_show_custom_columns_for_subtasks_with_global_setting
    issue = issues :issues_004
    Issue.generate! project_id: 2, parent_issue_id: issue.id

    @request.session[:user_id] = 1
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_list_defaults: @global_settings do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select '#issue_tree td.created_on'
      assert_select '#issue_tree td.updated_on'
    end
  end

  def test_show_without_closed_relations
    issue = issues :issues_004

    related_issue = Issue.generate! project_id: 2, status_id: 1
    open_relation = IssueRelation.create! issue_from: related_issue,
                                          issue_to: issue,
                                          relation_type: 'relates'

    closed_issue = Issue.generate! project_id: 2, status_id: 5
    closed_relation = IssueRelation.create! issue_from: closed_issue,
                                            issue_to: issue,
                                            relation_type: 'relates'

    @request.session[:user_id] = 1
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_scope: 'without_closed_by_default',
                         issue_list_defaults: @global_settings do
      get :show, params: { id: issue.id }

      assert_response :success

      assert_select "tr#relation-#{open_relation.id}"
      assert_select "tr#relation-#{closed_relation.id}", count: 0
    end
  end

  def test_show_without_closed_subtasks
    issue = issues :issues_002
    open_issue = Issue.generate! project_id: 1, parent_issue_id: issue.id, status_id: 1
    closed_issue = Issue.generate! project_id: 1, parent_issue_id: issue.id, status_id: 5

    @request.session[:user_id] = 1
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_scope: 'without_closed_by_default',
                         issue_list_defaults: @global_settings do
      get :show, params: { id: issue.id }

      assert_response :success

      assert_select "tr#issue-#{open_issue.id}"
      assert_select "tr#issue-#{closed_issue.id}", count: 0
    end
  end
end
