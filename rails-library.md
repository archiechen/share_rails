1.   创建一个rails项目。

    ```bash
    rails new library
    cd library
    bundle install
    ```
1.   启动rails

    ```bash
    rails s
    ```
1.   都说WEBrick很烂，我们换成thin吧，再加一些测试依赖的bundle

    ```ruby
    gem "thin"
    group :test, :development do
      gem "rspec-rails"
      gem 'factory_girl_rails'
    end
    ```
1.   配置rspec和factory_girl

    ```bash
    rails generate rspec:install
    ```

    ```ruby
    appliction.rb

    config.generators do |g|
      g.fixture_replacement :factory_girl
    end
    ```
1.   创建图书的CRUD

    ```bash
    rails g scaffold book name:string amount:integer
    ```
1.   创建数据库

    ```bash
    rake db:migrate
    ```
1.   so easy，我们来美化一下。

    ```ruby
    gem "therubyracer"
    gem "less-rails"
    gem "twitter-bootstrap-rails"
    ```

    ```bash
    bundle install
    rails generate bootstrap:install static

    rails g bootstrap:layout application fluid
    rails g bootstrap:themed Books
    ```
1.   删除默认页面，重启rails

    ```bash
    rm ./public/index.html
    mv ./public/favicon.ico ./app/assets/images/
    rails s
    ```
1.   设置root path,默认图书列表为首页

    ```ruby
    root :to => "books#index"
    ```
1.   Run testss
    
    ```bash
    rake spec
    ```

1.   有书不能借啊，来套用户管理的功能吧

    ```ruby
    gem "devise"
    ```

    ```bash
    bundle install

    rails generate devise:install

    rails generate devise User

    rake db:migrate
    ```
1.   登录后才能看到图书列表

    ```ruby
    before_filter :authenticate_user!
    ```
1.   我要退出！

    ```
    <% if current_user %>
      <ul class="nav pull-right">
        <li class="dropdown"><a href="#" class="dropdown-toggle" data-toggle="dropdown"><%= current_user.email %><b class="caret"></b></a>
          <ul class="dropdown-menu">
              <li><%= link_to(raw('<i class="icon-cog"></i>Change Password'), edit_registration_path(:user)) %></li>
              <li class="divider"></li>
              <li><%= link_to(raw('<i class="icon-off"></i> Logout'), destroy_user_session_path, :method => :delete) %> </li>
          </ul>
        </li>
      </ul>
    <% else %>
      <ul class="nav pull-right">
        <li><%= link_to('Register', new_registration_path(:user)) %> </li>
        <li><%= link_to('Login', new_session_path(:user)) %></li>
      </ul>
    <% end %>
    ```
1.   Run tests & repair
    
    ```bash
    rake spec

    cp ../library_bak/spec/controllers/books_controller_spec.rb ./spec/controllers/
    cp ../library_bak/spec/support/* ./spec/support/
    cp ../library_bak/spec/spec_helper.rb ./spec/
    cp ../library_bak/spec/factories/* ./spec/factories/
    cp ../library_bak/spec/requests/books_spec.rb ./spec/requests/
    ```
1.   要借书，先写测试，从route测试开始

    ```ruby
    it "routes to #lend" do
      put("/books/1/lend").should route_to("books#lend", :id => "1")
    end

    resources :books do
      member do
        put :lend
      end
    end
    ```   
1.   然后是controller
    
    ```ruby
    describe "PUT lend" do
      it "借书时，调用user的lend方法" do
        Book.any_instance.should_receive(:lend_to).with(@user)
        put :lend, {:id => @book.to_param}
      end

      it "借书成功后，返回图书列表" do
        put :lend, {:id => @book.to_param}
        response.should redirect_to(books_url)
      end
    end

    def lend
      @book = Book.find(params[:id])
      @book.lend_to(current_user)

      respond_to do |format|
        format.html { redirect_to books_url }
        format.json { head :no_content }
      end
    end
    ```
1.   然后是model
    
    ```ruby
    before(:each) do
      @book = FactoryGirl.create(:book,:amount=>2)
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
    end

    def lend_to(user)
      self.amount-=1
      self.save()
    end
    ```
1.   view就不测了，增加个借阅按钮

    ```html
    <%= link_to t('.lend', :default => t("helpers.links.lend")), 
                      lend_book_path(book), :class => 'btn btn-mini', :method => :put %>
    ```
1.   书都借成负数了！补充测试先。

    ```ruby
    #book_spec.rb
    it "如果amount==0,lend_to返回false" do
      @book_zero.lend_to(@user).should be_false
    end
    ```
    最简单的修复方法

    ```ruby
    def lend_to(user)
      if self.amount < 1
        return false
      end
      self.amount-=1
      self.save()
    end
    ```
    bad small，单一职责，逻辑混乱。
    在book.rb中增加以下代码，并删除if代码块
    ```ruby
    validate :amount_not_less_zero

    private
      def amount_not_less_zero
        if self.amount<0
          errors[:amount]<<"都被借光啦！"
        end
      end
    ```
    还要修复controller的测试

    ```ruby
    def valid_attributes
      { "name" => "MyString", "amount" => 1 }
    end
    ```
1.   想知道是自己借了哪些书？什么时间借的？ok，我们需要建一个中间对象做many-to-many关联。

    ```bash
    rails g model lending_book user_id:integer book_id:integer
    ```

    ```ruby
    class LendingBook < ActiveRecord::Base
      attr_accessible :book_id, :user_id

      belongs_to :book
      belongs_to :user
    end

    #user.rb add
    has_many :lending_books
    has_many :books, :through => :lending_books

    #book.rb add
    has_many :lending_books
    has_many :users, :through => :lending_books
    ```
    ```bash
    rake db:migrate
    ```
1.   模型建好了，先写测试。

    ```ruby
    it "如果amount>=1,lend_to后，创建一个LendingBook" do
      expect{
        @book.lend_to(@user)
      }.to change(LendingBook, :count).by(1)
    end

    def lend_to(user)
      self.amount-=1
      self.lending_books.create(:book=>self,:user=>user)
      self.save()
    end
    ```
1.   看样子需要个事务，如果没有会怎么样？写个测试吧。

    ```ruby
    it "如果amount==0,lend_to不会创建LendingBook" do
      expect{
        @book_zero.lend_to(@user)
      }.to change(LendingBook, :count).by(0)
    end
    ```
    擦，明明没借到书，还生成了借书记录，赶紧加上事务处理。
    
    ```ruby
    def lend_to(user)
      Book.transaction do
        self.amount-=1
        self.lending_books.create(:book=>self,:user=>user)
        self.save!()
      end
    end
    ```
    呃，抛异常了，在controller里处理异常,并且修复model测试
    ```ruby
    begin
      @book.lend_to(current_user)
    rescue ActiveRecord::RecordInvalid => invalid
      logger.warn invalid
    end

    #修改测试，不会返回false了！
    it "如果amount==0,lend_to抛出异常" do
      expect{
        @book_zero.lend_to(@user)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "如果amount==0,lend_to抛出异常后不会新增LendingBook" do
      lambda{
        expect{
          @book_zero.lend_to(@user)
        }.to raise_error(ActiveRecord::RecordInvalid)
      }.should change(LendingBook, :count).by(0)
    end
    ```
1.   我可不想一直在这个图书列表里操作，至少还书的时候不是！那我们分成两个功能吧：［我借的书，我要借书］，顺便清理菜单；先上测试！
    
    ```ruby
    it "routes to #myboosk" do
      get("/mybooks").should route_to("books#mybooks")
    end

    match '/mybooks' => 'books#mybooks', :as => "mybooks", :via => :get

    #controller spec

    @book_of_user = FactoryGirl.create(:book) do |book|
      book.lending_books.create(:book=>book,:user=>@user)
    end

    describe "GET mybooks" do
      it "只显示我借到的书" do
        get :mybooks
        assigns(:books).should eq([@book_of_user])
      end
    end

    #controller
    def mybooks
      @books = current_user.books

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @books }
      end
    end
    ```

    ```html
    <%- model_class = Book -%>
    <div class="page-header">
      <h1><%=t '.title', :default => model_class.model_name.human.pluralize %></h1>
    </div>
    <table class="table table-striped">
      <thead>
        <tr>
          <th><%= model_class.human_attribute_name(:id) %></th>
          <th><%= model_class.human_attribute_name(:name) %></th>
        </tr>
      </thead>
      <tbody>
        <% @books.each do |book| %>
          <tr>
            <td><%= link_to book.id, book_path(book) %></td>
            <td><%= book.name %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    ```
1.   我想看到这本书是什么时候借的。
    view中显示的应该是LendingBook,而不是Book，重构吧！从router开始。

    ```ruby
    #lending_books_routing_spec.rb
    require "spec_helper"

    describe LendingBooksController do
      describe "routing" do
        
        it "routes to #lending_book" do
          get("/lending_books").should route_to("lending_books#index")
        end

      end
    end

    #routers.rb
    resources :lending_books
    ```
    创建controller
    
    ```bash
    rails g controller lending_books
    ```
    增加controller的spec
    
    ```ruby
    #encoding: utf-8
    require 'spec_helper'

    describe LendingBooksController do
      before(:each) do
        @user = FactoryGirl.create(:user)

        @book_of_user = FactoryGirl.create(:book) do |book|
          book.lending_books.create(:book=>book,:user=>@user)
        end

        sign_in @user
      end

      describe "GET index" do
        it "只显示我借到的书" do
          get :index
          assigns(:lending_books).should eq(@book_of_user.lending_books)
        end
      end
    end

    #controller
    class LendingBooksController < ApplicationController
      before_filter :authenticate_user!

      def index
        @lending_books = current_user.lending_books

        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @lending_books }
        end
      end

    end
    ```
    删除原来mybooks的测试代码，mybooks.html.erb从books移到lending_books,并重名命index.html.erb，修改内容

    ```html
    <%- model_class = LendingBook -%>
    <div class="page-header">
      <h1><%=t '.title', :default => model_class.model_name.human.pluralize %></h1>
    </div>
    <table class="table table-striped">
      <thead>
        <tr>
          <th><%= model_class.human_attribute_name(:book) %></th>
          <th><%= model_class.human_attribute_name(:created_at) %></th>
        </tr>
      </thead>
      <tbody>
        <% @lending_books.each do |lending_book| %>
          <tr>
            <td><%= lending_book.book.name %></td>
            <td><%=l lending_book.created_at %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    ```

    ```ruby
    time_ago_in_words
    ```

1.   有借有还，再借不难。
    
    ```ruby
    it "routes to #destroy" do
      delete("/lending_books/1").should route_to("lending_books#destroy",:id=>"1")
    end

    #controller spec
    @book_of_user = FactoryGirl.create(:book) do |book|
      @lending_book = book.lending_books.create(:book=>book,:user=>@user)
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
    end

    #controller
    def destroy
      @lending_book = current_user.lending_books.find(params[:id])
      @lending_book.destroy

      respond_to do |format|
        format.html { redirect_to lending_books_url }
        format.json { head :no_content }
      end
    end
    ```

    ```html
    <%- model_class = LendingBook -%>
    <div class="page-header">
      <h1><%=t '.title', :default => model_class.model_name.human.pluralize %></h1>
    </div>
    <table class="table table-striped">
      <thead>
        <tr>
          <th><%= model_class.human_attribute_name(:book) %></th>
          <th><%= model_class.human_attribute_name(:created_at) %></th>
          <th><%=t '.actions', :default => t("helpers.actions") %></th>
        </tr>
      </thead>
      <tbody>
        <% @lending_books.each do |lending_book| %>
          <tr>
            <td><%= lending_book.book.name %></td>
            <td><%= time_ago_in_words lending_book.created_at %></td>
            <td>
                <%= link_to t('.destroy', :default => t("helpers.links.return")),
                          lending_book_path(lending_book),
                          :method => :delete,
                          :data => { :confirm => t('.confirm', :default => t("helpers.links.confirm", :default => 'Are you sure?')) },
                          :class => 'btn btn-mini btn-danger' %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    ```
1.   还了别人也不能借，没更新amount?先测试！

    ```ruby
    #lending_books_controller_spec.rb
    it "还书后，书的Amount加1" do
      delete :destroy, {:id => @lending_book.to_param}
      Book.find(@lending_book.book.to_param).amount.should eql(2)
    end

    #lending_book.rb
    after_destroy :update_book_amount

    private
      def update_book_amount
        self.book.amount+=1
        self.book.save()
      end
    ```
1.   只要有GET和DELETE
    
    ```ruby
    :only => [:index, :destroy] 
    ```

1.   谁都能管理图书列表太乱了吧，加上授权功能吧。

    ```ruby
    gem "cancan"
    ```

    ```bash 
    bundle install
    ```

    ```bash
    rails g cancan:ability
    ```
1.   我们只要能区分是否为admin就行了，user.admin?

    ```ruby
    class Ability
      include CanCan::Ability

      def initialize(user)
        user ||= User.new # guest user (not logged in)

        if user.admin?
          can :manage, :all
        else
          can :read, :all
        end
        
      end
    end
    ```
1.   修改数据库结构，别忘了设置default
    
    ```bash
    rails g migration add_admin_to_user admin:boolean
    ```
1.   修改新建按钮，只有admin可以看到
    
    ```html
    <% if can? :create, Book %>
    <%= link_to t('.new', :default => t("helpers.links.new")),
                new_book_path,
                :class => 'btn btn-primary' %>
    <% end %>
    ```
    运行测试，失败了。

    ```ruby
    #加在before中
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    controller.stub(:current_ability) { @ability }

    it "renders a list of books" do
      @ability.can :create, Book
      render

      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "tr>td", :text => "Name".to_s, :count => 2
      assert_select "tr>td", :text => 1.to_s, :count => 2

      assert_select ".btn-primary"
      
    end
    ```
1.   在controller中增加限制
  
    ```ruby
    authorize_resource


    #修改测试books_controller_spec.rb
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    @controller.stub(:current_ability) { @ability }
    @ability.can :manage, Book
    ```