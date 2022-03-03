// subject and tracker are already included in the first row by default
$(function() {
  $('#available_settings_issue_view_columns option[value="tracker"]').remove();
  $('#available_settings_issue_view_columns option[value="subject"]').remove();
  $('#available_c option[value="tracker"]').remove();
  $('#available_c option[value="subject"]').remove();
});
