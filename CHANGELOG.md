
# CHANGELOG

## v2.0.0

* Added `SearchFlip::Connection`
* [BREAKING] Changed `SearchFlip::Index.base_url` to `SearchFlip::Index.connection`
* [BREAKING] Changed `SearchFlip.version` to `SearchFlip::Connection#version`
* [BREAKING] Changed `SearchFlip.aliases` to `SearchFlip::Connection#update_aliases`
* [BREAKING] Changed `SearchFlip.msearch` to `SearchFlip::Connection#msearch`
* [BREAKING] Removed `base_url` param from `SearchFlip::Critiera#execute`
* Added `SearchFlip::Connection#get_aliases`
* Added `SearchFlip::Connection#get_indices`
* Added `SearchFlip::Connection#alias_exists?`
* Added `SearchFlip::Index#with_settings` and `SearchFlip::Criteria#with_settings`

## v1.1.0

* Added `Criteria#find_results_in_batches` to scroll through the raw results
* Fixed bug in `Criteria#find_in_batches` which possibly stopped scrolling too early
* Added delegation for `should`, `should_not`, `must` and `must_not`
* Migrated To FactoryBot

