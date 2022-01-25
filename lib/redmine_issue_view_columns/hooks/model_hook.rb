# frozen_string_literal: true

module RedmineIssueViewColumns
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        return if Rails.version < '6.0'

        RedmineIssueViewColumns.setup!
      end
    end
  end
end
