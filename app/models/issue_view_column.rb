# frozen_string_literal: true

class IssueViewColumn < ActiveRecord::Base
  belongs_to :project

  scope :sorted, -> { order :position }
end
