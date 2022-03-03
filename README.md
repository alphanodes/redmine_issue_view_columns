Redmine Issue View Columns plugin for Redmine
=============================================

[![Tests](https://github.com/AlphaNodes/redmine_privacy_terms/workflows/Tests/badge.svg)](https://github.com/AlphaNodes/redmine_privacy_terms/actions?query=workflow%3A"Run+Tests) ![Run Linters](https://github.com/AlphaNodes/redmine_privacy_terms/workflows/Run%20Linters/badge.svg)

Redmine plugin to customize shown columns in subtasks and related issues on issue page

Basic functionality
-------------------

* Provide configurable list of columns that are shown for subtasks list in issue view
* Provide configurable list of columns that are shown for related issues in issue view
* Configuration is possible per project
* There is a possibility to define global configuration in admin area. Global configuration is then applied to all projects that don't have the plugin module activated.
* Subject and tracker columns are not configurable by this plugin. This information is always shown, as this is the default behavior of these sections in Redmine
* Related issues contain an icon that is used to remove the relation from corresponding ticket. This icon is always shown as the last column on the right side of the related issues table
* Same configuration is applied to both subtasks and related issues sections

Requirements
------------

* Redmine version >= 4.1.0
* Redmine Plugin: [additionals](https://github.com/alphanodes/additionals)
* Ruby version >= 2.6

Installation
------------

Install ``redmine_privacy_terms`` plugin for `Redmine`

    cd $REDMINE_ROOT
    git clone git://github.com/alphanodes/redmine_issue_view_columns.git plugins/redmine_issue_view_columns
    git clone git://github.com/alphanodes/additionals.git plugins/additionals
    bundle install --without development test
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production

Restart Redmine (application server) and you should see the plugin show up in the Plugins page.

Credits
-------

This plugins is a fork of <https://github.com/kenan3008/redmine_issue_view_columns>
Plugin is inspired by <https://www.redmine.org/plugins/subtaskcolumns> and <https://www.redmine.org/plugins/subtask_list_columns>
