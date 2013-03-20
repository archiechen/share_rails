class LendingBook < ActiveRecord::Base
  attr_accessible :book_id, :user_id, :book, :user

  belongs_to :book
  belongs_to :user

  after_destroy :update_book_amount

  private
    def update_book_amount
      self.book.amount+=1
      self.book.save()
    end
end
