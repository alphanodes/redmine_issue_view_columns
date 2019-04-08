# Redmine Issue View Columns Plugin

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

Compatibility
-------------

Plugin is compatible with Redmine 3.4.x and 4.0.x

Installation
------------

* Clone https://github.com/kenan3008/redmine_issue_view_columns or download zip to **redmine_dir/plugins/** folder
```
$ git clone https://github.com/kenan3008/redmine_issue_view_columns.git
```
* From redmine root directory, run: 
```
$ rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_issue_view_columns
```
* Restart redmine

Credits
-------

Plugin is inspired by http://www.redmine.org/plugins/subtaskcolumns and http://www.redmine.org/plugins/subtask_list_columns
