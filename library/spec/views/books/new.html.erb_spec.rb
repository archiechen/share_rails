require 'spec_helper'

describe "books/new" do
  before(:each) do
    assign(:book, stub_model(Book,
      :name => "MyString",
      :amount => 1
    ).as_new_record)
  end

  it "renders new book form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", books_path, "post" do
      assert_select "input#book_name[name=?]", "book[name]"
      assert_select "input#book_amount[name=?]", "book[amount]"
    end
  end
end
