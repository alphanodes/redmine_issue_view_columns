# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter[SimpleCov::Formatter::HTMLFormatter,
                                                              SimpleCov::Formatter::RcovFormatter]

  SimpleCov.start :rails do
    add_filter 'init.rb'
    root File.expand_path "#{File.dirname __FILE__}/.."
  end
end

require File.expand_path "#{File.dirname __FILE__}/../../../test/test_helper"
require File.expand_path "#{File.dirname __FILE__}/../../additionals/test/global_test_helper"
require File.expand_path "#{File.dirname __FILE__}/../../additionals/test/crud_controller_base"

module RedmineIssueViewColumns
  module TestHelper
    include Additionals::GlobalTestHelper

    def prepare_tests
      Role.where(id: 1).find_each do |r|
        r.permissions << :manage_issue_view_columns
        r.save
      end

      Project.where(id: 1).find_each do |project|
        EnabledModule.create project: project, name: 'issue_view_columns'
      end
    end
  end

  module PluginFixturesLoader
    def fixtures(*table_names)
      dir = "#{File.dirname __FILE__}/fixtures/"
      table_names.each do |x|
        ActiveRecord::FixtureSet.create_fixtures dir, x if File.exist? "#{dir}/#{x}.yml"
      end
      super table_names
    end
  end

  class ControllerTest < Redmine::ControllerTest
    include RedmineIssueViewColumns::TestHelper
    extend PluginFixturesLoader
  end

  class TestCase < ActiveSupport::TestCase
    include RedmineIssueViewColumns::TestHelper
    extend PluginFixturesLoader
  end

  class IntegrationTest < Redmine::IntegrationTest
    include RedmineIssueViewColumns::TestHelper
    extend PluginFixturesLoader
  end
end
