# frozen_string_literal: true

class IssueViewColumn < Rails.version < '7.1' ? ActiveRecord::Base : ApplicationRecord
  belongs_to :project

  scope :sorted, -> { order :position }
end
