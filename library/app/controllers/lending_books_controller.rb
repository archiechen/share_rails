class LendingBooksController < ApplicationController
  before_filter :authenticate_user!

  def index
    @lending_books = current_user.lending_books

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @lending_books }
    end
  end

  def destroy
    @lending_book = current_user.lending_books.find(params[:id])
    @lending_book.destroy

    respond_to do |format|
      format.html { redirect_to lending_books_url }
      format.json { head :no_content }
    end
  end
end
