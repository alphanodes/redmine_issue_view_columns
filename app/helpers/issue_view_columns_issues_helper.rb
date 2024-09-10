# frozen_string_literal: true

module IssueViewColumnsIssuesHelper
  def render_descendants_tree(issue)
    columns_list = get_fields_for_project issue
    # no field defined, then use render from core redmine (or whatever by other plugins loaded before this)
    return super if columns_list.count.zero?

    # Retrieve sorting settings and determine if sorting by directory/file model is enabled
    sort_dir_file_model = RedmineIssueViewColumns.setting(:sort_dir_file_model)
    collapsed_ids = issue.collapsed_ids.to_s.split.map(&:to_i)
    field_values = +""
    s = table_start_for_relations columns_list
    manage_relations = User.current.allowed_to? :manage_subtasks, issue.project
    rendered_issues = Set.new

    render_issues(issue, ->(child, level, hidden) {
      render_issue_row(child, level, hidden, columns_list, manage_relations, collapsed_ids, issue)
    }, collapsed_ids, columns_list, field_values, sort_dir_file_model)

    # Append the rendered field values and end the relations table
    s << field_values
    s << table_end_for_relations

    s.html_safe
  end

  def render_issue_row(child, level, hidden = false, columns_list, manage_relations, collapsed_ids, issue)
    # Construct the row classes with context menu and alternating row colors
    tr_classes = +"hascontextmenu #{child.css_classes}"
    tr_classes << " #{cycle("odd", "even")}" unless hidden
    tr_classes << " idnt-#{level}" if level.positive?

    # Generate buttons for deleting if the user has the right permissions
    buttons = if manage_relations
        link_to l(:label_delete_link_to_subtask),
                issue_path(id: child.id,
                           issue: { parent_issue_id: "" },
                           back_url: issue_path(issue.id),
                           no_flash: "1"),
                method: :put,
                data: { confirm: l(:text_are_you_sure) },
                title: l(:label_delete_link_to_subtask),
                class: "icon-only icon-link-break"
      else
        "".html_safe
      end
    buttons << link_to_context_menu

    # Build the content for each table cell
    field_content = content_tag("td", check_box_tag("ids[]", child.id, false, id: nil), class: "checkbox")

    # If all children are closed and hidden, do not show the expand/collapse button
    with_closed_issues = (params[:with_closed_issues] == "true")
    status_column = columns_list.find { |column| column.instance_variable_get(:@name) == :status }
    all_descendants_closed = child.descendants.all? do |descendant|
      column_content(status_column, descendant) == "Closed"
    end

    if child.descendants.any? && (!all_descendants_closed || with_closed_issues)
      # Generate toggle icon for expanding/collapsing subissues
      icon_class = collapsed_ids.include?(child.id) ? "icon icon-toggle-plus" : "icon icon-toggle-minus"
      expand_icon = content_tag("span", "", class: icon_class, onclick: "collapseExpand(this)")
      subject_content = "#{expand_icon} #{link_to_issue(child, project: (issue.project_id != child.project_id))}".html_safe
    else
      subject_content = link_to_issue(child, project: (issue.project_id != child.project_id))
    end

    field_content << content_tag("td", subject_content, class: "subject")

    # Add columns with their respective content
    columns_list.each do |column|
      field_content << content_tag("td", column_content(column, child), class: column.css_classes.to_s)
    end

    field_content << content_tag("td", buttons, class: "buttons")

    # Apply style to hide the row if hidden is true
    row_style = hidden ? "display: none;" : ""
    content_tag("tr", field_content, class: tr_classes, id: "issue-#{child.id}", style: row_style).html_safe
  end

  def render_issues(issue, render_issue_row, collapsed_ids, columns_list, field_values, sort_dir_file_model, rendered_issues = Set.new)
    render_issue_with_descendants = lambda do |parent, level, hidden = false|
      issues_with_subissues = []
      issues_without_subissues = []
      issues = []

      # Get direct descendants and sort them
      direct_descendants = parent.descendants.select { |descendant| descendant.parent_id == parent.id }
      sorted_issues = sort_issues(direct_descendants, columns_list)

      sorted_issues.each do |child|
        next if (child.closed? && !issue_columns_with_closed_issues?) || (rendered_issues.include?(child.id) && sort_dir_file_model == "1")

        rendered_issues.add(child.id)

        child_hidden = hidden || collapsed_ids.include?(child.id)

        # Traverse sorted issues recursively
        if sort_dir_file_model == "1"
          if child.descendants.any?
            issues_with_subissues << render_issue_row.call(child, level, hidden)
            subissues_with, subissues_without = render_issue_with_descendants.call(child, level + 1, child_hidden)
            issues_with_subissues.concat(subissues_with)
            issues_with_subissues.concat(subissues_without)
          else
            issues_without_subissues << render_issue_row.call(child, level, child_hidden) if child.parent_id == parent.id
          end
        else
          issues << render_issue_row.call(child, level, hidden)
          subissues = render_issue_with_descendants.call(child, level + 1, child_hidden)
          issues.concat(subissues)
        end
      end

      if sort_dir_file_model == "1"
        return issues_with_subissues, issues_without_subissues
      else
        return issues
      end
    end

    if sort_dir_file_model == "1"
      issues_with_subissues, issues_without_subissues = render_issue_with_descendants.call(issue, 0)
      field_values << issues_with_subissues.join("").html_safe
      field_values << issues_without_subissues.join("").html_safe
    else
      rendered_issues = render_issue_with_descendants.call(issue, 0, false)
      field_values << rendered_issues.join("").html_safe
    end
  end

  def sort_issues(issues, columns_list)
    columns_sorting_setting = RedmineIssueViewColumns.setting(:columns_sorting)
    return issues unless columns_sorting_setting.present?

    # Build sorting criteria as an array of hashes with keys :column_name and :direction
    sorting_criteria = columns_sorting_setting.split(",").map do |column_setting|
      column_name, direction = column_setting.split(":").map(&:strip)
      { column_name: column_name, direction: direction }
    end

    # Use the extracted comparison lambda
    sorted_issues = issues.to_a.sort(&comparison_lambda(sorting_criteria))

    sorted_issues
  end

  # Define a method for comparison lambda
  def comparison_lambda(sorting_criteria)
    lambda do |a, b|
      sorting_criteria.each do |criterion|
        column_name = criterion[:column_name]
        direction = criterion[:direction] == "ASC" ? 1 : -1

        a_value = column_name.start_with?("cf_") ? a.custom_field_value(column_name.sub(/^cf_/, "")) : get_nested_attribute_value(a, column_name) rescue nil
        b_value = column_name.start_with?("cf_") ? b.custom_field_value(column_name.sub(/^cf_/, "")) : get_nested_attribute_value(b, column_name) rescue nil

        comparison = if a_value.nil? && b_value.nil?
            0
          elsif a_value.nil?
            -1
          elsif b_value.nil?
            1
          else
            case a_value
            when Numeric
              a_value <=> b_value
            when String
              a_value.to_s <=> b_value.to_s
            when Enumerable
              a_value.length <=> b_value.length
            when User
              (a_value.firstname + a_value.lastname) <=> (b_value.firstname + b_value.lastname)
            when ActiveRecord::Base
              a_value.respond_to?(:name) ? a_value.name <=> b_value.name : a_value.id <=> b_value.id
            else
              a_value.to_s <=> b_value.to_s
            end
          end

        # If comparison is not zero, return it adjusted by direction
        return comparison * direction if comparison != 0
      end
      0
    end
  end

  # Retrieves a nested attribute value from an object based on a dot-separated attribute path ( used for parent.subject )
  def get_nested_attribute_value(object, attribute_path)
    attribute_parts = attribute_path.split(".")
    attribute_parts.inject(object) do |current_object, method|
      current_object.public_send(method) if current_object
    end
  end

  # Renders the list of related issues on the issue details view
  def render_issue_relations(issue, relations)
    columns_list = get_fields_for_project issue
    return super if columns_list.count.zero?

    manage_relations = User.current.allowed_to? :manage_issue_relations, issue.project
    s = table_start_for_relations columns_list
    relations.each do |relation|
      other_issue = relation.other_issue issue
      next if other_issue.closed? && !issue_columns_with_closed_issues?

      tr_classes = "hascontextmenu #{other_issue.css_classes} #{cycle "odd", "even"} #{relation.css_classes_for other_issue}"
      buttons = if manage_relations
          link_to l(:label_relation_delete),
                  relation_path(relation),
                  remote: true,
                  method: :delete,
                  data: { confirm: l(:text_are_you_sure) },
                  title: l(:label_relation_delete),
                  class: "icon-only icon-link-break"
        else
          "".html_safe
        end
      buttons << link_to_context_menu

      subject_content = relation.to_s(@issue) { |other| link_to_issue other, project: Setting.cross_project_issue_relations? }.html_safe

      field_content = content_tag("td", check_box_tag("ids[]", other_issue.id, false, id: nil), class: "checkbox") +
                      content_tag("td", subject_content, class: "subject")

      columns_list.each do |column|
        field_content << content_tag("td", column_content(column, other_issue), class: column.css_classes.to_s)
      end

      field_content << content_tag("td", buttons, class: "buttons")

      s << content_tag("tr", field_content,
                       id: "relation-#{relation.id}",
                       class: tr_classes)
    end

    s << table_end_for_relations
    s.html_safe
  end

  def issue_scope_with_closed?(issue_scope)
    %w[without_closed_by_default without_closed].exclude? issue_scope
  end

  def issue_columns_with_closed_issues?
    return @issue_columns_with_closed_issues if defined?(issue_columns_with_closed_issues)

    issue_scope = RedmineIssueViewColumns.setting :issue_scope
    return true if issue_scope_with_closed? issue_scope

    @issue_columns_with_closed_issues = if issue_scope == "without_closed_by_default"
        RedminePluginKit.true? params[:with_closed_issues]
      else
        RedminePluginKit.false? params[:without_closed_issues]
      end
  end

  def link_to_closed_issues(issue, issue_scope)
    css_class = "closed-issue-switcher"
    if issue_scope == "without_closed_by_default"
      if issue_columns_with_closed_issues?
        link_to l(:label_hide_closed_issues), issue_path(issue), class: "#{css_class} hide-switch"
      else
        link_to l(:label_show_closed_issues), issue_path(issue, with_closed_issues: true), class: "#{css_class} show-switch"
      end
    elsif issue_columns_with_closed_issues?
      link_to l(:label_hide_closed_issues), issue_path(issue, without_closed_issues: true), class: "#{css_class} hide-switch"
    else
      link_to l(:label_show_closed_issues), issue_path(issue), class: "#{css_class} show-switch"
    end
  end

  private

  def table_start_for_relations(columns_list)
    # Retrieve minimum width settings for columns
    min_width_setting = RedmineIssueViewColumns.setting(:columns_min_width)
    min_widths = {}
    if min_width_setting.present?
      min_width_setting.split(",").each do |column_setting|
        column_name, min_width = column_setting.split(":").map(&:strip)
        min_widths[column_name] = min_width
      end
    end

    s = +'<div class="autoscroll"><table class="list issues odd-even view-columns"><thead>'

    s << content_tag("th", l(:field_subject), class: "subject", style: min_widths["Subject"].present? ? "min-width: #{min_widths["Subject"]};" : "")
    columns_list.each do |column|
      min_width_style = min_widths[column.name.to_s].present? ? "min-width: #{min_widths[column.name.to_s]};" : ""
      s << content_tag("th", column.caption, class: column.name, style: min_width_style)
    end

    s << content_tag("th", "", class: "buttons")
    s << "</thead><tbody>"
    s
  end

  def table_end_for_relations
    "</tbody></table></div>"
  end

  def get_fields_for_project(issue)
    query = IssueQuery.new
    query.project = issue.project
    available_fields = query.available_inline_columns
    first_cols = %w[tracker subject]
    subtask_fields = []
    issue.project.issue_view_columns.each do |field|
      next if first_cols.include? field

      proj_field = available_fields.select { |f| f.name.to_s == field }
      subtask_fields << proj_field[0] if proj_field.count.positive?
    end

    subtask_fields # this should be an array of QueryColumn
  end
end
