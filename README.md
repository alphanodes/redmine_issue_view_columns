# Redmine Issue View Columns plugin for Redmine

[![Tests](https://github.com/AlphaNodes/redmine_issue_view_columns/workflows/Tests/badge.svg)](https://github.com/AlphaNodes/redmine_issue_view_columns/actions?query=workflow%3A"Run+Tests) ![Run Linters](https://github.com/AlphaNodes/redmine_issue_view_columns/workflows/Run%20Linters/badge.svg)

Redmine plugin to customize shown columns in subtasks and related issues on issue page

## Basic functionality

* Provide configurable list of columns that are shown for subtasks list in issue view
* Provide configurable list of columns that are shown for related issues in issue view
* Configuration is possible per project
* There is a possibility to define global configuration in admin area. Global configuration is then applied to all projects that don't have the plugin module activated.
* Subject and tracker columns are not configurable by this plugin. This information is always shown, as this is the default behavior of these sections in Redmine
* Related issues contain an icon that is used to remove the relation from corresponding ticket. This icon is always shown as the last column on the right side of the related issues table
* Same configuration is applied to both subtasks and related issues sections

## Requirements

* Redmine version >= 5.0
* Redmine Plugin: [additionals](https://github.com/alphanodes/additionals)
* Ruby version >= 3.0

## Installation

Install `redmine_issue_view_columns` plugin for `Redmine`

    cd $REDMINE_ROOT
    git clone git://github.com/alphanodes/redmine_issue_view_columns.git plugins/redmine_issue_view_columns
    git clone git://github.com/alphanodes/additionals.git plugins/additionals
    bundle config set --local without 'development test'
    bundle install
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production

Restart Redmine (application server) and you should see the plugin show up in the Plugins page.

## Uninstall

Uninstall `redmine_issue_view_columns` plugin.

    cd $REDMINE_ROOT
    rm -rf plugins/redmine_issue_view_columns public/plugin_assets/redmine_issue_view_columns

## License

This plugin is licensed under the terms of GNU/GPL v2.
See [LICENSE](LICENSE) for details.

## Redmine Copyright

The redmine_issue_view_columns is a plugin extension for Redmine Project Management Software, whose Copyright follows.
Copyright (C) 2006-  Jean-Philippe Lang

Redmine is a flexible project management web application written using Ruby on Rails framework.
More details can be found in the doc directory or on the official website <http://www.redmine.org>

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

## Credits

This plugins is a fork of <https://github.com/kenan3008/redmine_issue_view_columns>
Plugin is inspired by <https://www.redmine.org/plugins/subtaskcolumns> and <https://www.redmine.org/plugins/subtask_list_columns>
