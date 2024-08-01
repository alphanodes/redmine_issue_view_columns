# frozen_string_literal: true

require File.expand_path "../../test_helper", __FILE__

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

    @global_settings = { "column_names" => %w[created_on updated_on] }
  end

  def test_show_author_column_for_related_issues_with_project_setting
    issue = issues :issues_002

    get :show, params: { id: issue.id }

    assert_response :success
    assert_select "#relations td.author"
  end

  def test_show_default_columns_for_related_issues_without_global_setting
    issue = issues :issues_004
    related_issue = Issue.generate! project_id: 2

    IssueRelation.create! issue_from: related_issue,
                          issue_to: issue,
                          relation_type: "relates"

    @request.session[:user_id] = 1
    with_plugin_settings "redmine_issue_view_columns", issue_list_defaults: {} do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select "#relations td.due_date"
    end
  end

  def test_show_custom_columns_for_related_issues_with_global_setting
    issue = issues :issues_004
    related_issue = Issue.generate! project_id: 2

    IssueRelation.create! issue_from: related_issue,
                          issue_to: issue,
                          relation_type: "relates"

    @request.session[:user_id] = 1
    with_plugin_settings "redmine_issue_view_columns",
                         issue_list_defaults: @global_settings do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select "#relations td.created_on"
      assert_select "#relations td.updated_on"
    end
  end

  def test_show_author_column_for_subtasks_with_project_setting
    issue = issues :issues_002
    Issue.generate! project_id: 1, parent_issue_id: issue.id

    get :show, params: { id: issue.id }

    assert_response :success
    assert_select "#issue_tree td.author"
  end

  def test_show_default_columns_for_subtasks_without_global_setting
    issue = issues :issues_004
    Issue.generate! project_id: 2, parent_issue_id: issue.id

    @request.session[:user_id] = 1
    with_plugin_settings "redmine_issue_view_columns",
                         issue_list_defaults: {} do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select "#issue_tree td.due_date"
    end
  end

  def test_show_custom_columns_for_subtasks_with_global_setting
    issue = issues :issues_004
    Issue.generate! project_id: 2, parent_issue_id: issue.id

    @request.session[:user_id] = 1
    with_plugin_settings "redmine_issue_view_columns",
                         issue_list_defaults: @global_settings do
      get :show, params: { id: issue.id }

      assert_response :success
      assert_select "#issue_tree td.created_on"
      assert_select "#issue_tree td.updated_on"
    end
  end

  def test_show_without_closed_relations
    issue = issues :issues_004

    related_issue = Issue.generate! project_id: 2, status_id: 1
    open_relation = IssueRelation.create! issue_from: related_issue,
                                          issue_to: issue,
                                          relation_type: "relates"

    closed_issue = Issue.generate! project_id: 2, status_id: 5
    closed_relation = IssueRelation.create! issue_from: closed_issue,
                                            issue_to: issue,
                                            relation_type: "relates"

    @request.session[:user_id] = 1
    with_plugin_settings "redmine_issue_view_columns",
                         issue_scope: "without_closed_by_default",
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
    with_plugin_settings "redmine_issue_view_columns",
                         issue_scope: "without_closed_by_default",
                         issue_list_defaults: @global_settings do
      get :show, params: { id: issue.id }

      assert_response :success

      assert_select "tr#issue-#{open_issue.id}"
      assert_select "tr#issue-#{closed_issue.id}", count: 0
    end
  end

  def test_render_issue_tree_dir_file_model
    parent_issue = Issue.generate!(project_id: 1)
    child_issue1 = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id)
    child_issue2 = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id)
    grandchild_issue = Issue.generate!(project_id: 1, parent_issue_id: child_issue2.id)

    @request.session[:user_id] = 1

    with_plugin_settings "redmine_issue_view_columns",
                         sort_dir_file_model: "1" do
      get :show, params: { id: parent_issue.id }

      assert_response :success

      issue_rows = css_select("#issue_tree tr").map(&:to_html)

      # Extract the issue IDs from the rows
      issue_ids = issue_rows.map { |row| row[/id="issue-(\d+)"/, 1].to_i }

      # Assert that child_issue2 appears before child_issue1
      assert issue_ids.index(child_issue2.id) < issue_ids.index(child_issue1.id), "Child issue 2 should appear before child issue 1"

      # Assert that grandchild_issue appears after child_issue2
      assert issue_ids.index(grandchild_issue.id) > issue_ids.index(child_issue2.id), "Grandchild issue should appear after child issue 2"
    end
  end

  def test_render_issue_tree_default
    parent_issue = Issue.generate!(project_id: 1)
    child_issue1 = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id)
    child_issue2 = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id)
    grandchild_issue = Issue.generate!(project_id: 1, parent_issue_id: child_issue2.id)

    @request.session[:user_id] = 1

    with_plugin_settings "redmine_issue_view_columns",
                         sort_dir_file_model: "0" do
      get :show, params: { id: parent_issue.id }

      assert_response :success

      issue_rows = css_select("#issue_tree tr").map(&:to_html)

      # Extract the issue IDs from the rows
      issue_ids = issue_rows.map { |row| row[/id="issue-(\d+)"/, 1].to_i }

      # Assert that child_issue2 appears after child_issue1
      assert issue_ids.index(child_issue2.id) > issue_ids.index(child_issue1.id), "Child issue 2 should appear before child issue 1"

      # Assert that grandchild_issue appears after child_issue2
      assert issue_ids.index(grandchild_issue.id) > issue_ids.index(child_issue2.id), "Grandchild issue should appear after child issue 2"
    end
  end

  def test_min_width_setting_applies
    issue = Issue.generate!(project_id: 1)
    child_issue = Issue.generate!(project_id: 1, parent_issue_id: issue.id)

    @request.session[:user_id] = 1

    with_plugin_settings "redmine_issue_view_columns",
                         columns_min_width: "status:300px" do
      get :show, params: { id: issue.id }

      assert_response :success

      assert_select "th.status", true, "Expected 'Status' column to be present"

      style = css_select("th.status").first["style"]

      # Ensure the style attribute contains the min-width property
      assert_match(/min-width:\s*300px/, style, "Expected 'Status' column to have min-width of 300px")
    end
  end

  def test_sorting_criteria_and_order_for_columns
    parent_issue = Issue.generate!(project_id: 1)
    issue1 = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id, status_id: 1, author_id: 3)
    issue2 = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id, status_id: 1, author_id: 2)
    issue3 = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id, status_id: 2, author_id: 2)

    @request.session[:user_id] = 1

    with_plugin_settings "redmine_issue_view_columns",
                         columns_sorting: "status:ASC,author:DESC" do
      get :show, params: { id: parent_issue.id }

      assert_response :success

      issue_rows = css_select("#issue_tree tr").map(&:to_html)

      issue_ids = issue_rows.map { |row| row[/id="issue-(\d+)"/, 1].to_i }

      sorted_ids = [issue3.id, issue2.id, issue1.id]

      #Check that issues were sorted correctly by defined sorting criteria
      assert_equal sorted_ids, issue_ids, "Issues are not sorted correctly by status and author"
    end
  end

  def test_collapsed_issue_is_not_displayed
    parent_issue = Issue.generate!(project_id: 1)
    child_issue = Issue.generate!(project_id: 1, parent_issue_id: parent_issue.id)
    grandchild_issue = Issue.generate!(project_id: 1, parent_issue_id: child_issue.id)

    parent_issue.reload
    parent_issue.update!(collapsed_ids: child_issue.id.to_s)

    @request.session[:user_id] = 1

    get :show, params: { id: parent_issue.id }

    assert_response :success

    grandchild_issue_row = css_select("tr#issue-#{grandchild_issue.id}").first

    style = grandchild_issue_row["style"]

    # Check if the style attribute of children of issues included in collapsed_ids includes 'display: none'
    assert_match(/display:\s*none/, style, "Expected grandchild issue to have display: none")
  end
end
