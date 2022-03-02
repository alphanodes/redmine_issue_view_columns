# frozen_string_literal: true

Rails.application.routes.draw do
  resources :projects, only: [] do
    resource :issue_view_columns, only: %i[update]
  end
end
