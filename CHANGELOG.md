
# CHANGELOG

## v2.0.0

* **BREAKING**: Migration steps
  * Change `SearchFlip.version` to `SearchFlip::Connection#version`
  * Change `SearchFlip.msearch` to `SearchFlip::Connection#msearch`
  * Change `SearchFlip.aliases` to `SearchFlip::Connection#update_aliases`
  * Change `SearchFlip::Criteria#execute(base_url: '...')` to `SearchFlip::Criteria#execute(connection: SearchFlip::Connection.new(base_url: '...'))`
* Added `SearchFlip::Connection`
* Added `SearchFlip::Connection#update_aliases`
* Added `SearchFlip::Connection#get_aliases`
* Added `SearchFlip::Connection#alias_exists?`

## v1.1.0

* Added `Criteria#find_results_in_batches` to scroll through the raw results
* Fixed bug in `Criteria#find_in_batches` which possibly stopped scrolling too early
* Added delegation for `should`, `should_not`, `must` and `must_not`
* Migrated To FactoryBot

