# frozen_string_literal: true

module RedmineIssueViewColumns
  module Patches
    module ProjectPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods
      end

      module InstanceMethods
        def issue_view_columns?
          issue_view_columns.present?
        end

        def issue_view_columns
          @issue_view_columns = if module_enabled? :issue_view_columns
                                  IssueViewColumn.where(project_id: id).sorted.pluck(:name)
                                else
                                  columns_setting = RedmineIssueViewColumns.setting :issue_list_defaults
                                  if columns_setting.present? && columns_setting['column_names'].present?
                                    columns_setting['column_names']
                                  else
                                    []
                                  end
                                end
        end
      end
    end
  end
end
