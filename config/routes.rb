# frozen_string_literal: true

Rails.application.routes.draw do
  resources :projects, only: [] do
    resource :issue_view_columns, only: %i[update]
  end
end




    # See: http://guides.rubyonrails.org/routing.html
get "issue_view_columns", to: "issue_view_columns#index"
post "issue_view_columns", to: "issue_view_columns#update", as: "update_issue_view_columns"
# resources :subtask_columns
