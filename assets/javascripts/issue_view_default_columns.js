// subject and tracker are already included in the first row by default
$(document).ready(function () {
    $("#available_settings_issue_view_default_columns option[value='tracker']").remove();
    $("#available_settings_issue_view_default_columns option[value='subject']").remove();
    $("#available_c option[value='tracker']").remove();
    $("#available_c option[value='subject']").remove();
});