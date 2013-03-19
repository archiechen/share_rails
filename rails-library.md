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
        }.to change(@book,:amount).from(2).to(1)
      end
    end
    ```
1.   view就不测了，增加个借阅按钮

    ```html
    <%= link_to t('.lend', :default => t("helpers.links.lend")), 
                      lend_book_path(book), :class => 'btn btn-mini', :method => :put %>
    ```
1.   书都借成负数了！补充测试先。

    ```ruby
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
1.   我想知道是谁借了书？什么时间借的？ok，我们需要建一个中间对象做many-to-many关联。

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
