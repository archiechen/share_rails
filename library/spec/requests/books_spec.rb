#encoding: utf-8
require 'spec_helper'

describe "Books" do
  describe "GET /books" do
    it "获取图书列表页面，应该返回200" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      sign_in_as_a_user 
      get books_path
      response.status.should be(200)
    end
  end
end
