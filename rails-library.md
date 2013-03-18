*   创建一个rails项目。

    ```bash
    rails new library
    cd library
    bundle install
    ```

*   启动rails

    ```bash
    rails s
    ```
*   创建图书的CRUD

    ```bash
    rails g scaffold book name:string amount:integer
    ```
*   创建数据库

    ```bash
    rake db:migrate
    ```
*   so easy，我们来美化一下。

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
*   删除默认页面，重启rails

    ```bash
    rm ./public/index.html
    mv ./public/favicon.png ./app/assets/images/
    rails s
    ```
*   设置root path,默认图书列表为首页

    ```ruby
    root :to => "books#index"
    ```
*   有书不能借啊，来套用户管理的功能吧

    ```ruby
    gem "devise"
    ```

    ```bash
    bundle install

    rails generate devise:install

    rails generate devise User

    rake db:migrate
    ```
*   登录后才能看到图书列表

    ```ruby
    before_filter :authenticate_user!
    ```
*   我要退出！

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