# frozen_string_literal: true

class IssueViewColumn < ApplicationRecord
  belongs_to :project

  scope :sorted, -> { order :position }
end
