class CreateIssueViewColumns < Rails.version < "5.1" ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    create_table :issue_view_columns do |t|
      t.integer :project_id
      t.string :ident
      t.integer :order
    end
  end

  def down
    drop_table :issue_view_columns
  end
end
