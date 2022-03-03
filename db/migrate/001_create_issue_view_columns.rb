# frozen_string_literal: true

class CreateIssueViewColumns < ActiveRecord::Migration[5.2]
  def change
    create_table :issue_view_columns do |t|
      t.references :project,
                   type: :integer,
                   index: true,
                   foreign_key: { on_delete: :cascade }
      t.string :ident
      t.integer :order
    end
  end
end
