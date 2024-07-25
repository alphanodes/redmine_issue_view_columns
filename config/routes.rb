# frozen_string_literal: true

Rails.application.routes.draw do
  resources :projects, only: [] do
    resource :issue_view_columns, only: %i[update]
  end
  resources :issue_view_columns, only: [] do
    member do
      patch 'update_collapsed_ids'
    end
  end
end
