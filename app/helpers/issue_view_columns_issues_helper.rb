# frozen_string_literal: true

module IssueViewColumnsIssuesHelper
  def render_descendants_tree(issue)
    # Retrieve the list of columns to display for the project
    columns_list = get_fields_for_project(issue)
    return super if columns_list.empty?

    # Retrieve minimum width settings for columns
    min_width_setting = RedmineIssueViewColumns.setting(:columns_min_width)
    min_widths = {}
    if min_width_setting.present?
      min_width_setting.split(",").each do |column_setting|
        column_name, min_width = column_setting.split(":").map(&:strip)
        min_widths[column_name] = min_width
      end
    end

    # Retrieve sorting settings and determine if sorting by directory/file model is enabled
    sort_dir_file_model = RedmineIssueViewColumns.setting(:sort_dir_file_model)
    collapsed_ids = issue.collapsed_ids.to_s.split.map(&:to_i)
    field_values = +""
    s = table_start_for_relations(columns_list)
    manage_relations = User.current.allowed_to?(:manage_subtasks, issue.project)
    rendered_issues = Set.new

    # Determine which rendering method to use based on sorting model
    if sort_dir_file_model == "1"
      render_issues_dir_file_model(issue, ->(child, level, hidden) {
        render_issue_row(child, level, hidden, columns_list, min_widths, manage_relations, collapsed_ids, issue)
      }, collapsed_ids, rendered_issues, columns_list, field_values)
    else
      render_issues_default(issue, ->(child, level, hidden) {
        render_issue_row(child, level, hidden, columns_list, min_widths, manage_relations, collapsed_ids, issue)
      }, collapsed_ids, columns_list, field_values)
    end

    # Append the rendered field values and end the relations table
    s << field_values
    s << table_end_for_relations

    s.html_safe
  end

  def render_issue_row(child, level, hidden = false, columns_list, min_widths, manage_relations, collapsed_ids, issue)
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

    if child.descendants.any?
      # Generate toggle icon for expanding/collapsing subissues
      icon_class = collapsed_ids.include?(child.id) ? "icon icon-toggle-plus" : "icon icon-toggle-minus"
      expand_icon = content_tag("span", "", class: icon_class, onclick: "collapseExpand(this)")
      subject_content = "#{expand_icon} #{link_to_issue(child, project: (issue.project_id != child.project_id))}".html_safe
    else
      subject_content = link_to_issue(child, project: (issue.project_id != child.project_id))
    end

    field_content << content_tag("td", subject_content, class: "subject")

    # Add columns with their respective content and minimum width style
    columns_list.each do |column|
      column_name = column.caption # Convert symbol to string
      min_width_style = min_widths[column_name].present? ? "min-width: #{min_widths[column_name]};" : ""
      field_content << content_tag("td", column_content(column, child), class: column.css_classes.to_s, style: min_width_style)
    end

    field_content << content_tag("td", buttons, class: "buttons")

    # Apply style to hide the row if hidden is true
    row_style = hidden ? "display: none;" : ""
    content_tag("tr", field_content, class: tr_classes, id: "issue-#{child.id}", style: row_style).html_safe
  end

  def render_issues_dir_file_model(issue, render_issue_row, collapsed_ids, rendered_issues, columns_list, field_values)
    render_issue_with_descendants = lambda do |parent, level, hidden = false|
      issues_with_subissues = []
      issues_without_subissues = []

      # Get direct descendants and sort them
      direct_descendants = parent.descendants.select { |descendant| descendant.parent_id == parent.id }
      sorted_issues = sort_issues(direct_descendants, columns_list)

      sorted_issues.each do |child|
        next if (child.closed? && !issue_columns_with_closed_issues?) || rendered_issues.include?(child.id)

        rendered_issues.add(child.id)

        child_hidden = hidden || collapsed_ids.include?(child.id)

        # Append the folders(child with descendants) before the files(child without descendants)
        # Traverse sorted issues recursevely
        if child.descendants.any?
          issues_with_subissues << render_issue_row.call(child, level, hidden)
          subissues_with, subissues_without = render_issue_with_descendants.call(child, level + 1, child_hidden)
          issues_with_subissues.concat(subissues_with)
          issues_with_subissues.concat(subissues_without)
        else
          issues_without_subissues << render_issue_row.call(child, level, child_hidden) if child.parent_id == parent.id
        end
      end

      return issues_with_subissues, issues_without_subissues
    end

    # Start rendering from the top-level issue
    issues_with_subissues, issues_without_subissues = render_issue_with_descendants.call(issue, 0)

    # Append the rendered issues to the field values
    field_values << issues_with_subissues.join("").html_safe
    field_values << issues_without_subissues.join("").html_safe
  end

  def render_issues_default(issue, render_issue_row, collapsed_ids, columns_list, field_values)
    render_issue_with_descendants = lambda do |parent, level, hidden = false|
      issues = []

      # Get direct descendants and sort them
      direct_descendants = parent.descendants.select { |descendant| descendant.parent_id == parent.id }
      sorted_issues = sort_issues(direct_descendants, columns_list)

      # Traverse sorted issues recursevely
      sorted_issues.each do |child|
        next if (child.closed? && !issue_columns_with_closed_issues?)

        child_hidden = hidden || collapsed_ids.include?(child.id)

        issues << render_issue_row.call(child, level, hidden)
        subissues = render_issue_with_descendants.call(child, level + 1, child_hidden)
        issues.concat(subissues)
      end

      issues
    end

    # Start rendering from the root issue
    rendered_issues = render_issue_with_descendants.call(issue, 0, false)
    field_values << rendered_issues.join("").html_safe
  end

  def sort_issues(issues, columns_list)
    columns_sorting_setting = RedmineIssueViewColumns.setting(:columns_sorting)
    return issues unless columns_sorting_setting.present?

    # Build sorting criteria as an array of hashes with keys :column_name and :direction
    sorting_criteria = columns_sorting_setting.split(",").map do |column_setting|
      column_name, direction = column_setting.split(":").map(&:strip)
      { column_name: caption_to_name(column_name, columns_list).downcase, direction: direction }
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

        if column_name.start_with?("cf_")
          # Handle custom fields
          cf_id = column_name.sub(/^cf_/, "")
          a_value = CustomValue.where(customized_id: a.id, customized_type: "Issue", custom_field_id: cf_id).first&.value
          b_value = CustomValue.where(customized_id: b.id, customized_type: "Issue", custom_field_id: cf_id).first&.value
        else
          # Handle regular fields
          a_value = get_nested_attribute_value(a, column_name) rescue nil
          b_value = get_nested_attribute_value(b, column_name) rescue nil
        end

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

  def caption_to_name(caption, columns_list)
    # Create a mapping from column caption to column name
    caption_to_name_map = columns_list.each_with_object({}) do |column, hash|
      hash[column.caption] = column.name.to_s
    end

    # Return the column name corresponding to the given caption
    caption_to_name_map[caption] || caption
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
    s = +'<div class="autoscroll"><table class="list issues odd-even view-columns"><thead>'

    s << content_tag("th", l(:field_subject), class: "subject")
    columns_list.each do |column|
      s << content_tag("th", column.caption, class: column.name)
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
