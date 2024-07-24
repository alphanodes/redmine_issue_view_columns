class AddCollapsedIdsToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :collapsed_ids, :string, limit: 1000
  end
end
