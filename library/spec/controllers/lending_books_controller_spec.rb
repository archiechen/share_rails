#encoding: utf-8
require 'spec_helper'

describe LendingBooksController do
  before(:each) do
    @user = FactoryGirl.create(:user)

    @book_of_user = FactoryGirl.create(:book) do |book|
      @lending_book = book.lending_books.create(:book=>book,:user=>@user)
    end

    sign_in @user
  end

  describe "GET index" do
    it "只显示我借到的书" do
      get :index
      assigns(:lending_books).should eq(@book_of_user.lending_books)
    end
  end

  describe "DELETE destroy" do
    it "还书后，删除LendingBook" do
      expect {
        delete :destroy, {:id => @lending_book.to_param}
      }.to change(LendingBook, :count).by(-1)
    end

    it "还书后，返回已借图书列表" do
      delete :destroy, {:id => @lending_book.to_param}
      response.should redirect_to(lending_books_url)
    end

    it "还书后，书的Amount加1" do
      delete :destroy, {:id => @lending_book.to_param}
      Book.find(@lending_book.book.to_param).amount.should eql(2)
    end
  end

end