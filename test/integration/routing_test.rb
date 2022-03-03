# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class RoutingTest < Redmine::RoutingTest
  test 'issue_view_columns' do
    should_route 'PUT /projects/foo/issue_view_columns' => 'issue_view_columns#update', project_id: 'foo'
  end
end
