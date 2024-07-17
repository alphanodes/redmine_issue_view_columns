# frozen_string_literal: true

module IssueViewColumnsIssuesHelper
  def render_descendants_tree(issue)
    sort_dir_file_model = RedmineIssueViewColumns.setting(:sort_dir_file_model)
    columns_list = get_fields_for_project(issue)

    # Proceed with default rendering if no columns are defined
    return super if columns_list.empty?

    if sort_dir_file_model == '1'
      render_descendants_tree_dir_file_model(issue, columns_list)
    else
      render_descendants_tree_default(issue, columns_list)
    end
  end

  def render_descendants_tree_dir_file_model(issue, columns_list)
    field_values = +''
    s = table_start_for_relations(columns_list)
    manage_relations = User.current.allowed_to?(:manage_subtasks, issue.project)
    rendered_issues = Set.new

    render_issue_row = lambda do |child, level|
      tr_classes = +"hascontextmenu #{child.css_classes} #{cycle('odd', 'even')}"
      tr_classes << " idnt idnt-#{level}" if level.positive?

      buttons = if manage_relations
                  link_to l(:label_delete_link_to_subtask),
                          issue_path({ id: child.id,
                                       issue: { parent_issue_id: '' },
                                       back_url: issue_path(issue.id),
                                       no_flash: '1' }),
                          method: :put,
                          data: { confirm: l(:text_are_you_sure) },
                          title: l(:label_delete_link_to_subtask),
                          class: 'icon-only icon-link-break'
                else
                  ''.html_safe
                end
      buttons << link_to_context_menu

      field_content = content_tag('td', check_box_tag('ids[]', child.id, false, id: nil), class: 'checkbox')

      if child.descendants.any?
        expand_icon = content_tag('span', '+', class: 'expand-icon', title: 'Expand')
        subject_content = "#{expand_icon} #{link_to_issue(child, project: (issue.project_id != child.project_id))}".html_safe
      else
        subject_content = link_to_issue(child, project: (issue.project_id != child.project_id))
      end

      field_content << content_tag('td', subject_content, class: 'subject')

      columns_list.each do |column|
        field_content << content_tag('td', column_content(column, child), class: column.css_classes.to_s)
      end

      field_content << content_tag('td', buttons, class: 'buttons')

      content_tag('tr', field_content, class: tr_classes, id: "issue-#{child.id}").html_safe
    end

    render_issue_with_descendants = lambda do |parent, level|
      issues_with_subissues = []
      issues_without_subissues = []

      parent.descendants.visible.preload(:status, :priority, :tracker, :assigned_to).sort_by(&:lft).each do |child|
        next if (child.closed? && !issue_columns_with_closed_issues?) || rendered_issues.include?(child.id)

        rendered_issues.add(child.id)

        if child.descendants.any?
          issues_with_subissues << render_issue_row.call(child, level)
          subissues_with, subissues_without = render_issue_with_descendants.call(child, level + 1)
          issues_with_subissues.concat(subissues_with)
          issues_with_subissues.concat(subissues_without)
        else
          issues_without_subissues << render_issue_row.call(child, level) if child.parent_id == parent.id
        end
      end

      return issues_with_subissues, issues_without_subissues
    end

    issues_with_subissues, issues_without_subissues = render_issue_with_descendants.call(issue, 0)

    field_values << issues_with_subissues.join('').html_safe
    field_values << issues_without_subissues.join('').html_safe

    s << field_values
    s << table_end_for_relations

    s.html_safe
  end

  def render_descendants_tree_default(issue, columns_list)
    field_values = "".dup  # Ensure field_values is mutable
    s = String.new("<table class=\"list issues odd-even\">")

    s << content_tag('th', l(:field_subject), style: 'text-align:left')
    columns_list.each do |column|
      s << content_tag('th', column.caption)
    end

    s << content_tag('th', '', style: 'text-align:right') if Redmine::VERSION::MAJOR >= 4

    issue_list(issue.descendants.visible.preload(:status, :priority, :tracker, :assigned_to).sort_by(&:lft)) do |child, level|
      css = "issue issue-#{child.id} hascontextmenu #{child.css_classes}"
      css << " idnt idnt-#{level}" if level > 0

      field_content = content_tag('td', check_box_tag('ids[]', child.id, false, id: nil), class: 'checkbox') +
                      content_tag('td', link_to_issue(child, project: (issue.project_id != child.project_id)), class: 'subject', style: 'width: 30%')

      columns_list.each do |column|
        field_content << content_tag('td', column_content(column, child), class: column.css_classes.to_s)
      end

      field_content << content_tag('td', link_to_context_menu, class: 'buttons', style: 'text-align:right') if Redmine::VERSION::MAJOR >= 4

      field_values << content_tag('tr', field_content, class: css).html_safe
    end

    s << field_values
    s << '</table>'
    s.html_safe
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

      tr_classes = "hascontextmenu #{other_issue.css_classes} #{cycle 'odd', 'even'} #{relation.css_classes_for other_issue}"
      buttons = if manage_relations
                  link_to l(:label_relation_delete),
                          relation_path(relation),
                          remote: true,
                          method: :delete,
                          data: { confirm: l(:text_are_you_sure) },
                          title: l(:label_relation_delete),
                          class: 'icon-only icon-link-break'
                else
                  ''.html_safe
                end
      buttons << link_to_context_menu

      subject_content = relation.to_s(@issue) { |other| link_to_issue other, project: Setting.cross_project_issue_relations? }.html_safe

      field_content = content_tag('td', check_box_tag('ids[]', other_issue.id, false, id: nil), class: 'checkbox') +
                      content_tag('td', subject_content, class: 'subject')

      columns_list.each do |column|
        field_content << content_tag('td', column_content(column, other_issue), class: column.css_classes.to_s)
      end

      field_content << content_tag('td', buttons, class: 'buttons')

      s << content_tag('tr', field_content,
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

    @issue_columns_with_closed_issues = if issue_scope == 'without_closed_by_default'
                                          RedminePluginKit.true? params[:with_closed_issues]
                                        else
                                          RedminePluginKit.false? params[:without_closed_issues]
                                        end
  end

  def link_to_closed_issues(issue, issue_scope)
    css_class = 'closed-issue-switcher'
    if issue_scope == 'without_closed_by_default'
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

    s << content_tag('th', l(:field_subject), class: 'subject')
    columns_list.each do |column|
      s << content_tag('th', column.caption, class: column.name)
    end

    s << content_tag('th', '', class: 'buttons')
    s << '</thead><tbody>'
    s
  end

  def table_end_for_relations
    '</tbody></table></div>'
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
