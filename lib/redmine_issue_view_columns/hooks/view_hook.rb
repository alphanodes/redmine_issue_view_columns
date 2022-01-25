# frozen_string_literal: true

# This file is a part of redmine_automation,
# a automation plugin for Redmine.
#
# Copyright (c) 2021-2022 AlphaNodes GmbH
# https://alphanodes.com

module RedmineIssueViewColumns
  module Hooks
    class ViewHook < Redmine::Hook::ViewListener
      def view_issues_show_description_bottom(_context = {})
        stylesheet_link_tag 'issue_view_columns', plugin: 'redmine_issue_view_columns'
      end
    end
  end
end
