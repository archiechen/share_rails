class CreateLendingBooks < ActiveRecord::Migration
  def change
    create_table :lending_books do |t|
      t.integer :user_id
      t.integer :book_id

      t.timestamps
    end
  end
end
