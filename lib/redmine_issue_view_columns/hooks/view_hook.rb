# frozen_string_literal: true

# This file is a part of redmine_automation,
# a automation plugin for Redmine.
#
# Copyright (c) 2021-2022 AlphaNodes GmbH
# https://alphanodes.com

module RedmineIssueViewColumns
  module Hooks
    class ViewHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, partial: 'issues/columns_issue_description_bottom'
    end
  end
end
