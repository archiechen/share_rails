require "spec_helper"

describe LendingBooksController do
  describe "routing" do

    it "routes to #lending_book" do
      get("/lending_books").should route_to("lending_books#index")
    end

    it "routes to #destroy" do
      delete("/lending_books/1").should route_to("lending_books#destroy",:id=>"1")
    end

  end
end