# frozen_string_literal: true

class RenameIssueViewColumnsColumns < ActiveRecord::Migration[5.2]
  def change
    change_table :issue_view_columns, bulk: true do |t|
      t.rename :ident, :name
      t.rename :order, :position
    end

    add_index :issue_view_columns, :project_id unless index_exists? :issue_view_columns, :project_id
  end
end
