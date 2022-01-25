# frozen_string_literal: true

class CreateIssueViewColumns < ActiveRecord::Migration[5.2]
  def change
    create_table :issue_view_columns do |t|
      t.integer :project_id
      t.string :ident
      t.integer :order
    end
  end
end
