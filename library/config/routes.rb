Library::Application.routes.draw do
  devise_for :users

  resources :books do
    member do
      put :lend
    end
  end

  resources :lending_books,:only => [:index, :destroy] 
  
  root :to => "books#index"

end
