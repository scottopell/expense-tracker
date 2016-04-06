class CreateExpenses < ActiveRecord::Migration
  def change
    create_table :expenses do |t|
      t.decimal :amount
      t.string :category
      t.date :date
      t.string :user

      t.timestamps null: false
    end
  end
end
