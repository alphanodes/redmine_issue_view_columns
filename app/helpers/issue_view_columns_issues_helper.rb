module IssueViewColumnsIssuesHelper
  def render_descendants_tree(issue)
    columns_list = get_fields_for_project(issue)
    # no field defined, then use render from core redmine (or whatever by other plugins loaded before this)
    unless columns_list.count > 0
      return super
    end

    # continue here if there are fields defined
    field_values = ""
    s = '<table class="list issues odd-even">'

    # set header - columns names
    s << content_tag('th style="text-align:left"', l(:field_subject))
    columns_list.each do |column|
      s << content_tag("th", column.caption)
    end

    if (Redmine::VERSION::MAJOR >= 4)
      s << content_tag('th style="text-align:right"', l(:label_actions))
    end

    # set data
    issue_list(issue.descendants.visible.preload(:status, :priority, :tracker, :assigned_to).sort_by(&:lft)) do |child, level|
      css = "issue issue-#{child.id} hascontextmenu #{child.css_classes}"
      css << " idnt idnt-#{level}" if level > 0

      field_content = content_tag("td", check_box_tag("ids[]", child.id, false, id: nil), class: "checkbox") +
                      content_tag("td", link_to_issue(child, project: (issue.project_id != child.project_id)), class: "subject", style: "width: 30%")

      columns_list.each do |column|
        field_content << content_tag("td", column_content(column, child), class: "#{column.css_classes}")
      end

      if (Redmine::VERSION::MAJOR >= 4)
        field_content << content_tag('td', link_to_context_menu, class: 'buttons', style: "text-align:right")
      end

      field_values << content_tag("tr", field_content, class: css).html_safe
    end

    s << field_values
    s << "</table>"
    s.html_safe
  end

  # Renders the list of related issues on the issue details view
  def render_issue_relations(issue, relations)
    columns_list = get_fields_for_project(issue)
    unless columns_list.count > 0
      return super
    end

    manage_relations = User.current.allowed_to?(:manage_issue_relations, issue.project)

    s = '<table class="list issues odd-even">'

    # set header with columns names
    s << content_tag('th style="text-align:left"', l(:field_subject))
    s << content_tag('th style="text-align:center"', l(:field_status))

    columns_list.each do |column|
      next if column.caption == "Status"
      s << content_tag("th", column.caption)
    end

    s << content_tag('th style="text-align:right"', l(:label_actions))

    relations.each do |relation|
      other_issue = relation.other_issue(issue)
      css = "issue hascontextmenu #{other_issue.css_classes}"
      link = manage_relations ? link_to(l(:label_relation_delete),
                                        relation_path(relation),
                                        remote: true,
                                        method: :delete,
                                        data: { confirm: l(:text_are_you_sure) },
                                        title: l(:label_relation_delete),
                                        class: "icon-only icon-link-break") : ""

      field_content = content_tag("td", check_box_tag("ids[]", other_issue.id, false, id: nil), class: "checkbox") +
                      content_tag("td", relation.to_s(@issue) { |other| link_to_issue(other, project: Setting.cross_project_issue_relations?) }.html_safe, class: "subject", style: "width: 30%") +
                      content_tag("td", other_issue.status, class: "status")

      columns_list.each do |column|
        next if column.name == :status
        field_content << content_tag("td", column_content(column, other_issue), class: "#{column.css_classes}")
      end

      buttons = link
      buttons << link_to_context_menu if Redmine::VERSION::MAJOR >= 4
      field_content << content_tag('td', buttons, {class: 'buttons', style: 'text-align: right'}, false)

      s << content_tag("tr", field_content,
                       id: "relation-#{relation.id}",
                       class: css)
    end

    s << "</table>"
    s.html_safe
  end

  private

  def get_fields_for_project(issue)
    query = IssueQuery.new()
    query.project = issue.project
    available_fields = query.available_inline_columns
    subtask_fields = []

    unless issue.project.module_enabled?(:issue_view_columns)
      all_fields = Setting.plugin_redmine_issue_view_columns["issue_view_default_columns"] || []
    else
      all_fields = IssueViewColumns.all.select { |c| c.project_id == issue.project_id }.sort_by { |o| o.order }.collect { |f| f.ident } || []
    end

    all_fields.each do |field|
      if ["tracker", "subject"].include? field
        next
      end
      proj_field = available_fields.select { |f| f.name.to_s == field }
      subtask_fields << proj_field[0] if proj_field.count > 0
    end
    subtask_fields # this should be an array of QueryColumn
  end
end
