app = window.App ||= {}
app.plannings ||= {}

app.plannings.service = new class
  updateSelected: (url, planning) ->
    planning.utf8 = undefined
    token = planning.authenticity_token
    planning.authenticity_token = undefined

    @update(url,
      planning: planning
      items: app.plannings.selectable.getSelectedDays()
      authenticity_token: token
    ).fail((res) -> console.log('update error', res.status, res.statusText))

  update: (url, data) ->
    $.ajax({
      type: 'PATCH',
      url: url,
      data: @_buildParams(data)
    })

  delete: (url, ids) ->
    $.ajax(
      type: 'DELETE'
      url: url
      data: @_buildParams(planning_ids: ids)
    )

  addPlanningRow: (employee_id, work_item_id) ->
    return $.ajax(
      url: "#{window.location.origin}#{window.location.pathname}/new"
      data: @_buildParams(
        employee_id: employee_id
        work_item_id: work_item_id
      )
    )

  _buildParams: (params) ->
    $.extend(utf8: '✓', params, @_getFilterParams())

  _getFilterParams: () ->
    form = $('#planning_filter_form')
    form.serializeArray().reduce(((data, field) ->
      data[field.name] = field.value
      data
    ), {})
