# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class I18nTest < RedmineIssueViewColumns::TestCase
  include Redmine::I18n

  def setup
    User.current = nil
  end

  def teardown
    set_language_if_valid 'en'
  end

  def test_valid_languages
    assert_kind_of Array, valid_languages
    assert_kind_of Symbol, valid_languages.first
  end

  def test_locales_validness
    lang_files_count = Rails.root.glob('plugins/redmine_issue_view_columns/config/locales/*.yml').size

    assert_equal 2, lang_files_count

    valid_languages.each do |lang|
      assert set_language_if_valid(lang)
      case lang.to_s
      when 'en'

        assert_equal 'Scope', l(:label_view_columns_issue_scope)
      when 'de'

        assert_not l(:label_view_columns_issue_scope) == 'Scope', lang
      end
    end

    set_language_if_valid 'en'
  end
end
