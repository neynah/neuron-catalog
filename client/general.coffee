# -------------
# font awesome (see
# https://github.com/nate-strauser/meteor-font-awesome/blob/master/load.js )
head = document.getElementsByTagName("head")[0]

#Generate a style tag
style = document.createElement("link")
style.type = "text/css"
style.rel = "stylesheet"
style.href = "/css/font-awesome.min.css"
head.appendChild style

# -------------
Meteor.subscribe "driver_lines"
Meteor.subscribe "neuron_types"
Meteor.subscribe "brain_regions"
Meteor.subscribe "binary_data"
Meteor.subscribe "neuron_catalog_config"
Meteor.subscribe "settings_to_client"
Meteor.subscribe "userData"
Meteor.subscribe "archive_filestore"
Meteor.subscribe "cache_filestore"
Meteor.subscribe "zip_filestore"

# --------------------------------------------
# session variables
editing_name = new ReactiveVar(null)

DEFAULT_TITLE = 'neuron catalog'
Session.setDefault 'DocumentTitle',DEFAULT_TITLE

window.modal_save_func = null

# --------------------------------------------
# helper functions

@endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) isnt -1

@utf8_to_b64 = (str) ->
  window.btoa(unescape(encodeURIComponent(str)))

@b64_to_utf8 = (str) ->
  decodeURIComponent(escape(window.atob(str)))

window.get_route_from_name = (name) ->
  route = undefined
  if name is "DriverLines"
    route = Router.routes['driver_line_show']
  else if name is "NeuronTypes"
    route = Router.routes['neuron_type_show']
  else if name is "BrainRegions"
    route = Router.routes['brain_region_show']
  else route = Router.routes['binary_data_show']  if name is "BinaryData"
  route

window.get_collection_from_name = get_collection_from_name

# --------------------------------------------

Template.RawDocumentView.helpers
  raw_document: ->
    coll = window.get_collection_from_name(@collection)
    doc = coll.findOne({_id: @my_id})
    JSON.stringify doc, `undefined`, 2

Template.linkout.helpers
  path: ->
    coll = window.get_collection_from_name(@collection)
    doc = coll.findOne({_id: @my_id})
    window.get_route_from_name(@collection).path(doc)
  name: ->
    @doc.name

Template.next_previous_button.helpers
  get_linkout: ->
    coll = window.get_collection_from_name(@collection)
    my_doc = coll.findOne({_id:@my_id})
    if !my_doc?
      return
    if @which=="next"
      op = "$gt"
      direction = 1
    else
      op = "$lt"
      direction = -1
      # assert @which=="previous"

    # Did I mention how much I do not understand how JavaScript and
    # Coffeescript automatically quote string literals unless using
    # square brackets?
    sort_key = window.get_sort_key(@collection)
    query = {}
    query[sort_key] = {}
    query[sort_key][op]=my_doc[sort_key]
    sort_options = {}
    sort_options[sort_key]=direction
    options = {limit:1}
    options['sort'] = sort_options
    cursor = coll.find(query,options)
    if cursor.count() == 0
      return
    arr = cursor.fetch()
    doc = arr[0]
    result = {}
    result["collection"]=@collection
    result["my_id"]=doc['_id']
    result["doc"]=doc
    result

# --------------------------------------------

window.jump_table =
  DriverLines:
    remove: (x) ->
      remove_driver_line x
    delete_template_name: "driver_line_show_brief"
    base_route: "driver_lines"

  NeuronTypes:
    remove: (x) ->
      remove_neuron_type x
    delete_template_name: "neuron_type_show_brief"
    base_route: "neuron_types"

  BrainRegions:
    remove: (x) ->
      remove_brain_region x
    delete_template_name: "brain_region_show_brief"
    base_route: "brain_regions"

  BinaryData:
    remove: (x) ->
      remove_binary_data x
    delete_template_name: "binary_data_show_brief"
    base_route: "binary_data"

Template.top_content_row2.helpers
  editing_name: ->
    d = editing_name.get()
    return false unless d?
    return true if @_id is d._id & @collection is d.collection
    false

Template.top_content_row2.events "click .edit-name": (e, tmpl) ->
  editing_name.set(tmpl.data)
  Deps.flush() # update DOM before focus
  ni = tmpl.find("#name-input")
  ni.value = @name
  window.activateInput ni
  return

Template.top_content_row2.events window.okCancelEvents("#name-input",
  ok: (value,evt) ->
    if editing_name.get() == null
      # Hmm, why do we get here? Cancel was clicked.
      return
    coll = window.get_collection_from_name(@collection)
    coll.update @_id,
      $set:
        name: value

    editing_name.set(null)
    return

  cancel: (evt) ->
    editing_name.set(null)
    return
)

Template.delete_button.events
  "click .delete": (e) ->
    e.preventDefault()

    my_info = window.jump_table[@collection]
    data =
      body_template_name: my_info.delete_template_name
      body_template_data: @my_id
    my_collection_name = @collection
    my_id = @my_id

    window.dialog_template = bootbox.dialog
      message: window.renderTmp(Template.DeleteDialog,data)
      title: "Do you want to delete this?"
      buttons:
        close:
          label: "Close"
        delete:
          label: "Delete"
          className: "btn-danger"
          callback: ->
            my_info.remove my_id
            route_name = my_info.base_route
            Router.go route_name

# -------------

Template.raw_button.events
  "click .raw": (event, template) ->
    event.preventDefault()
    data =
      collection: @collection
      my_id: @my_id
    window.dialog_template = bootbox.dialog
      message: window.renderTmp(Template.RawDocumentView,data)
      title: "Raw document view"
      buttons:
        close:
          label: "Close"
    window.dialog_template.off("shown.bs.modal") # do not focus on button

# -------------

@append_spinner = (div) ->
  $(div).html("Loading...")

# -------------

Template.show_user_date.helpers
  pretty_username: ->
    doc = Meteor.users.findOne {_id:this.userId}
    if doc? and doc.profile? and doc.profile.name?
      return doc.profile.name
    "userID "+this.userId

  pretty_time: ->
    timestamp = Date(this.time)
    moment(this.time).fromNow()

# --------

Template.registerHelper "rtfd", ->
  result =
    base_url: 'https://neuron-catalog.readthedocs.org'
    language: 'en'
    version: 'latest'

Template.registerHelper "neuron_catalog_version", ->
  return neuron_catalog_version

Template.registerHelper "get_brain_regions", (doc,type) ->
  result = []
  for brain_region in doc.brain_regions
    if type in brain_region.type
      result.push brain_region
  result

Template.registerHelper "activeIfTemplateIn", () ->
  currentRoute = Router.current()
  if !currentRoute?
    return ""
  if !currentRoute.route?
    return ""
  for arg in arguments
    if arg is currentRoute.lookupTemplate()
      return "active"

Template.registerHelper "currentUser", ->
  # Mimic the normal meteor accounts system from IronRouter template.
  Meteor.user()

Template.registerHelper "binary_data_cursor", ->
  BinaryData.find {}

Template.registerHelper "isInReaderRole", ->
  NeuronCatalogApp.checkRole( Meteor.user(), ReaderRoles )

Template.registerHelper "isInWriterRole", ->
  NeuronCatalogApp.checkRole( Meteor.user(), WriterRoles )

Template.registerHelper "pathForName", (routeName) ->
  route = Router.routes[routeName]
  route.path({_id: @_id, name: make_safe(@name)})

Template.registerHelper "isSandstorm", ->
  NeuronCatalogApp.isSandstorm()

Template.registerHelper "hasPermission", (permissionName) ->
  NeuronCatalogApp.checkRole(Meteor.user(),[permissionName])

Template.registerHelper "defaultTitle", () ->
  DEFAULT_TITLE

Deps.autorun ->
  document.title = Session.get('DocumentTitle')
