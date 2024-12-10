# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class ProjectTest < RedmineIssueViewColumns::TestCase
  def setup
    prepare_tests
    User.current = nil
  end

  def test_issue_view_columns_with_global_settings
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_list_defaults: { 'column_names' => %w[created_on updated_on] } do
      project = projects :projects_003

      assert project.issue_view_columns?
      assert_equal %w[created_on updated_on], project.issue_view_columns
    end
  end

  def test_issue_view_columns_with_project_settings
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_list_defaults: { 'column_names' => %w[created_on updated_on] } do
      project = projects :projects_001

      assert project.issue_view_columns?
      assert_equal %w[author status], project.issue_view_columns
    end
  end

  def test_issue_view_columns_without_columns
    with_plugin_settings 'redmine_issue_view_columns',
                         issue_list_defaults: {} do
      project = projects :projects_003

      assert_not project.issue_view_columns?
      assert_kind_of Array, project.issue_view_columns
      assert_empty project.issue_view_columns
    end
  end
end
