// subject and tracker are already included in the first row by default
$(function() {
  $('#available_settings_issue_list_defaults_column_names option[value="tracker"]').remove();
  $('#available_settings_issue_list_defaults_column_names option[value="subject"]').remove();
  $('#tab-content-issue_view_columns #available_c option[value="tracker"]').remove();
  $('#tab-content-issue_view_columns #available_c option[value="subject"]').remove();
});
