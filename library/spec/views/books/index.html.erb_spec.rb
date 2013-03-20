require 'spec_helper'

describe "books/index" do
  before(:each) do
    assign(:books, [
      stub_model(Book,
        :name => "Name",
        :amount => 1,
        :created_at => Time.now
      ),
      stub_model(Book,
        :name => "Name",
        :amount => 1,
        :created_at => Time.now
      )
    ])
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    controller.stub(:current_ability) { @ability }
  end

  it "renders a list of books" do
    @ability.can :create, Book
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "a",:text=> "New"
  end
end
