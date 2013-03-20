#encoding: utf-8
class Book < ActiveRecord::Base
  attr_accessible :amount, :name

  validate :amount_not_less_zero

  has_many :lending_books
  has_many :users, :through => :lending_books

  def lend_to(user)
    Book.transaction do
      self.amount-=1
      self.lending_books.create(:book=>self,:user=>user)
      self.save!()
    end
  end


  private
    def amount_not_less_zero
      if self.amount.nil? or self.amount<0
        errors[:amount]<<"都被借光啦！"
      end
    end
end
