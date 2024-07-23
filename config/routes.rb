# frozen_string_literal: true

Rails.application.routes.draw do
  resources :projects, only: [] do
    resource :issue_view_columns, only: %i[update]
  end
  resources :custom_issues do
    member do
      patch 'update_collapsed_ids'
    end
  end
  patch 'settings/update_column_settings', to: 'column_settings#update_column_settings'
end
