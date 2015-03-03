# data model
# Loaded on both the client and the server

@SettingsToClient = new Meteor.Collection("settings_to_client")
@S3ConfigStatus = new Meteor.Collection("s3_config_status")
@NeuronCatalogConfig = new Meteor.Collection("neuron_catalog_config")
@DriverLines = new Meteor.Collection("driver_lines")
@BinaryData = new Meteor.Collection("binary_data")
@NeuronTypes = new Meteor.Collection("neuron_types")
@BrainRegions = new Meteor.Collection("brain_regions")

# ----------------------------------------
@ReaderRoles = ['admin','read-write','read-only']
@WriterRoles = ['admin','read-write']

# define our schemas

Schemas = {}

Schemas.NeuronCatalogConfig = new SimpleSchema(
  project_name:
    type: String
    label: "A short string giving the name of the project"

  data_authors:
    type: String
    label: "A short string giving the name of the contributors to the data. Can contain raw HTML."

  blurb:
    type: String
    label: "An optional string with more information describing the project. Can contain raw HTML."
    optional: true
)
NeuronCatalogConfig.attachSchema(Schemas.NeuronCatalogConfig)

shallow_copy = (obj) ->
  newobj = {}
  for attrname of obj
    newobj[attrname] = obj[attrname]
  newobj

compose = (objects...) ->
  # This merges N objects while making shallow copies one level deep.
  result = {}
  for obj in objects
    for attrname of obj
      result[attrname] = shallow_copy(obj[attrname])
  result

NamedWithTagsHistoryComments =
  _id:
    type: String
    optional: true # let Meteor/Mongo create one if not specified

  name:
    type: String

  tags:
    label: "Tags"
    type: [String]

  "tags.$":
    type: String

  # Force value to be current date (on server) upon update.
  last_edit_time:
    type: Number
    autoValue: ->
      Date.now()

  # Force value to be current user upon update.
  last_edit_user:
    type: String
    autoValue: ->
      @userId

  # Automatically update a history array.
  edits:
    type: [Object]
    autoValue: ->
      if @isInsert
        [
          time: Date.now()
          userId: @userId
        ]
      else
        $push:
          time: Date.now()
          userId: @userId

  "edits.$.time":
    type: Number
    optional: true

  "edits.$.userId":
    type: String
    optional: true

  comments:
    type: [Object]

  "comments.$.comment":
    type: String

  "comments.$.time":
    type: Number
    autoValue: ->
      Date.now()

  "comments.$.userId":
    type: String
    autoValue: ->
      @userId

LinksImages =
  images:
    label: "Images and volumes"
    type: [String]

  "images.$":
    type: String
    label: "_id of doc in BinaryData collection"

NamedWithTagsImagesHistoryComments = compose(NamedWithTagsHistoryComments,LinksImages)

LinksNeuronTypes =
  neuron_types:
    type: [String]

  "neuron_types.$":
    type: String
    label: "_id of doc in NeuronTypes collection"

LinksBrainRegions =
  brain_regions:
    type: [Object]

  "brain_regions.$._id":
    type: String
    label: "_id of doc in BrainRegions collection"

  "brain_regions.$.type":
    type: [String]

  "brain_regions.$.type.$":
    type: String
    allowedValues: ["input", "output", "unspecified"]

HasSynonyms =
  synonyms:
    type: [String]

  "synonyms.$":
    type: String
    label: "synonym to name"

HasBestDriverLines =
  best_driver_lines:
    type: [String]

  "best_driver_lines.$":
    type: String
    label: "_id of doc in DriverLines collection"

HasFlyCircuitIdids =
  flycircuit_idids:
    type: [Number]

  "flycircuit_idids.$":
    type: Number
    label: "idid value in Flycircuit.tw database"

# Schemas.DriverLines -------------------
Schemas.DriverLines = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments, LinksNeuronTypes, HasFlyCircuitIdids, LinksBrainRegions))
DriverLines.attachSchema( Schemas.DriverLines )

# Schemas.NeuronTypes ------------------
Schemas.NeuronTypes = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments, HasSynonyms, HasBestDriverLines, HasFlyCircuitIdids, LinksBrainRegions))
NeuronTypes.attachSchema( Schemas.NeuronTypes )

# Schemas.BrainRegions ------------------
Schemas.BrainRegions = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments))
BrainRegions.attachSchema( Schemas.BrainRegions )

# Schemas.BinaryData ------------------
#  This schema has grown organically and should be cleaned up!
BinaryDataSpec =
  s3_bucket:
    type: String
  s3_region:
    type: String
  s3_key:
    type: String
  s3_upload_done:
    type: Boolean
  lastModifiedDate:
    type: Date
  thumb_s3_key:
    type: String
    optional: true
  thumb_width:
    type: Number
    optional: true
  thumb_height:
    type: Number
    optional: true
  width:
    type: Number
    optional: true
  height:
    type: Number
    optional: true
  cache_s3_key:
    type: String
    optional: true
  cache_width:
    type: Number
    optional: true
  cache_height:
    type: Number
    optional: true
  type:
    type: String
    optional: true

Schemas.BinaryData = new SimpleSchema(
  compose(NamedWithTagsHistoryComments,BinaryDataSpec))
BinaryData.attachSchema( Schemas.BinaryData )


Schemas.User = new SimpleSchema(
  username:
    type: String
    regEx: /^[a-z0-9A-Z_\.]{3,15}$/
  emails:
    type: [ Object ]
    optional: true
  'emails.$.address':
    type: String
    regEx: SimpleSchema.RegEx.Email
  'emails.$.verified': type: Boolean
  createdAt:
    type: Date
    denyUpdate: true
  services:
    type: Object
    optional: true
    blackbox: true
  roles:
    type: [String]
    optional: true
    blackbox: true
  )
Meteor.users.attachSchema Schemas.User
