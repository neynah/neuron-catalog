@get_collection_from_name = (name) ->
  coll = undefined
  if name is "DriverLines"
    coll = DriverLines
  else if name is "NeuronTypes"
    coll = NeuronTypes
  else if name is "BrainRegions"
    coll = BrainRegions
  else if name is "BinaryData"
    coll = BinaryData
  else if name is "Meteor.users"
    coll = Meteor.users
  else if name is "NeuronCatalogConfig"
    coll = NeuronCatalogConfig
  else if name is "SettingsToClient"
    coll = SettingsToClient
  else
    throw new Error("unknown collection name "+name)
  coll

@export_data = () ->
  collections = {}
  for collection_name in ["NeuronCatalogConfig","DriverLines","NeuronTypes","BrainRegions","BinaryData","Meteor.users","SettingsToClient"]
    coll = get_collection_from_name( collection_name )
    this_coll = {}
    coll.find().forEach (doc) ->
      if collection_name=="Meteor.users"
        # only save usernames
        doc = {_id: doc._id, profile: {name: doc.profile.name}}
      this_coll[doc._id]= doc
    collections[collection_name]=this_coll
  all_data = {collections: collections, 'export_date': new Date().toISOString()}
  raw_json = JSON.stringify(all_data)

@ensure_latest_json_schema = ( payload_raw ) ->
  payload = {}
  file_version = payload_raw.collections.SettingsToClient.settings.SchemaVersion
  this_version = SettingsToClient.findOne({_id:'settings'}).SchemaVersion
  if this_version != file_version
    throw new Error('This neuron-catalog .json file was saved with a different '+
           'schema. Converting between schemas is not implemented')
  payload = payload_raw.collections

# ----

@get_fileObj = (doc, keyname) ->
  if keyname == "archive"
    fileObj = ArchiveFileStore.findOne _id: doc.archiveId
  else if keyname == "cache"
    fileObj = CacheFileStore.findOne _id: doc.cacheId
  else if keyname == "thumb"
    fileObj = CacheFileStore.findOne _id: doc.thumbId
  fileObj
