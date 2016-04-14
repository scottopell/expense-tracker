class ExpenseUserToUserReference < ActiveRecord::Migration
  def change
    add_column :expenses, :user_id, :int
    remove_column :expenses, :user
  end
end
