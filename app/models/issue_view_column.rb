# frozen_string_literal: true

class IssueViewColumn < AdditionalsApplicationRecord
  belongs_to :project

  scope :sorted, -> { order :position }
end
