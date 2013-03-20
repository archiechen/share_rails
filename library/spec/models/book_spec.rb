#encoding: utf-8
require 'spec_helper'

describe Book do
  before(:each) do
    @book = FactoryGirl.create(:book,:amount=>2)
    @book_zero = FactoryGirl.create(:book,:amount=>0)
    @user = FactoryGirl.create(:user)
  end

  describe "User lend book" do
    it "如果amount>=1,lend_to返回true" do
      @book.lend_to(@user).should be_true
    end

    it "如果amount>=1,lend_to后，amount减1" do
      expect{
        @book.lend_to(@user)
      }.to change(@book,:amount).by(-1)
    end

    it "如果amount==0,lend_to抛出异常" do
      expect{
        @book_zero.lend_to(@user)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "如果amount>=1,lend_to后，创建一个LendingBook" do
      expect{
        @book.lend_to(@user)
      }.to change(LendingBook, :count).by(1)
    end

    it "如果amount==0,lend_to抛出异常后不会新增LendingBook" do
      lambda{
        expect{
          @book_zero.lend_to(@user)
        }.to raise_error(ActiveRecord::RecordInvalid)
      }.should change(LendingBook, :count).by(0)
    end
  end

end
