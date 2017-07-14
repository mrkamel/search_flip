
# ElasticSearch

[![Build Status](https://secure.travis-ci.org/mrkamel/elastic_search.png?branch=master)](http://travis-ci.org/mrkamel/elastic_search)

Using the ElasticSearch gem it is dead-simple to create index classes that
correspond to [ElasticSearch](https://www.elastic.co/) indices and to manipulate, query and aggregate
these indices using a chainable, concise, yet powerful DSL. Finally, the
ElasticSearch gem supports ElasticSearch Server 1.x, 2.x, 5.x. Check section
[Feature Support](#feature-support) for version dependent features.


```ruby
CommentIndex.search("hello world", default_field: "title").where(visible: true).aggregate(:user_id).sort(id: "desc")

CommentIndex.aggregate(:user_id) do |aggregation|
  aggregation.aggregate(histogram: { date_histogram: { field: "created_at", interval: "month" }})
end

CommentIndex.range(:created_at, gt: Date.today - 1.week, lt: Date.today).where(state: ["approved", "pending"])
```

## Reference Docs

See [http://www.rubydoc.info/github/mrkamel/elastic_search](http://www.rubydoc.info/github/mrkamel/elastic_search)

## Install

Add this line to your application's Gemfile:

```ruby
gem 'elastic_search'
```

and then execute

```
$ bundle
```

or install it via

```
$ gem install elastic_search
```

## Config

You can change global config options like:

```ruby
ElasticSearch::Config[:environment] = "development"
ElasticSearch::Config[:base_url] = "http://127.0.0.1:9200"
```

Available config options are:

* `index_prefix` to have a prefix added to your index names automatically. This
  can be useful to separate the indices of e.g. testing and development environments.
* `base_url` to tell ElasticSearch how to connect to your cluster
* `bulk_limit` a global limit for bulk requests
* `environment` tells ElasticSearch the current environment. This is used to
  e.g. automatically refresh an index when indexing/deleting records in test
  environment.

## Usage

First, create a separate class for your index and include `ElasticSearch::Index`.

```ruby
class CommentIndex
  include ElasticSearch::Index
end
```

Then tell the Index about the type name, the correspoding model and how to
serialize the model for indexing.

```ruby
class CommentIndex
  include ElasticSearch::Index

  def self.type_name
    "comments"
  end

  def self.model
    Comment
  end

  def self.serialize(comment)
    {
      id: comment.id,
      username: comment.username,
      title: comment.title,
      message: comment.message
    }
  end
end
```

Please note, ElasticSearch (the server) allows to have multiple types per
index. However, this forces to have the same mapping for fields having the same
name even though the fields live in different types of the same index. Thus,
this gem is using a different index for each type by default, but you can
change that. Simply supply a custom `index_name`.

```ruby
class CommentIndex
  # ...

  def self.index_name
    "custom_index_name"
  end

  # ...
end
```

To specify a custom mapping:

```ruby
class CommentIndex
  # ...

  def self.mapping
    {
      comments: {
        properties: {
          # ...
        }
      }
    }
  end

  # ...
end
```

Then you can interact with the index:

```ruby
CommentIndex.create_index
CommentIndex.index_exists?
CommentIndex.delete_index
CommentIndex.update_mapping
```

index records (automatically uses the bulk API):

```ruby
CommentIndex.import(Comment.all)
CommentIndex.import(Comment.first)
CommentIndex.import([Comment.find(1), Comment.find(2)])
CommentIndex.import(Comment.where("created_at > ?", Time.now - 7.days))
```

query records:

```ruby
CommentIndex.total_entries
# => 2838

CommentIndex.search("title:hello").records
# => [#<Comment ...>, #<Comment ...>, ...]

CommentIndex.where(username: "mrkamel").total_entries
# => 13

CommentIndex.aggregate(:username).aggregations(:username)
# => {1=>#<ElasticSearch::Result doc_count=37 ...>, 2=>... }
...
```

delete records:

```ruby
# for ElasticSearch 2.x, the delete-by-query plugin is required for the
# following query:

CommentIndex.match_all.delete

# or delete manually via the bulk API:

CommentIndex.match_all.find_each do |record|
  CommentIndex.bulk do |indexer|
    indexer.delete record.id
  end
end
```

## Advanced Usage

The ElasticSearch gem supports even more advanced usages, like e.g. post
filters, filtered aggregations or nested aggregations via simple to use
API methods.

### Post filters

All relation methods (`#where`, `#where_not`, `#range`, etc.) are available
in post filter mode as well, ie. filters/queries applied after aggregations
are calculated. Checkout the ElasticSearch docs for further info.

```ruby
query = CommentIndex.aggregate(:user_id)
query = query.post_where(reviewed: true)
query = query.post_search("username:a*")
```

Checkout [PostFilterableRelation](http://www.rubydoc.info/github/mrkamel/elastic_search/ElasticSearch/PostFilterableRelation)
for a complete API reference.

### Aggregations

The ElasticSearch gem allows to elegantly specify nested aggregations,
no matter how deeply nested:

```ruby
query = OrderIndex.aggregate(:username, order: { revenue: "desc" }) do |aggregation|
  aggregation.aggregate(revenue: { sum: { field: "price" }})
end
```

Generally, aggregation results returned by ElasticSearch Server are wrapped in
a `Hashie::Mash`, such thath you can access them via:

```ruby
query.aggregations(:username)["mrkamel"].revenue.value
```

Still, if you want to get the raw aggregations returned by ElasticSearch Server,
access them without supplying any aggregation name to `#aggregations`:

```ruby
query.aggregations # => returns the raw aggregation section

query.aggregations["username"]["buckets"].detect { |bucket| bucket["key"] == "mrkamel" }["revenue"]["value"] # => 238.50
```

Once again, the relation methods (`#where`, `#range`, etc.) are available in
aggregations as well:

```ruby
query = OrderIndex.aggregate(average_price: {}) do |aggregation|
  aggregation = aggregation.match_all
  aggregation = aggregation.where(user_id: current_user.id) if current_user

  aggregation.aggregate(average_price: { avg: { field: "price" }})
end

query.aggregations(:average_price).average_price.value
```

Checkout [AggregatableRelation](http://www.rubydoc.info/github/mrkamel/elastic_search/ElasticSearch/AggregatableRelation)
as well as [AggregationRelation](http://www.rubydoc.info/github/mrkamel/elastic_search/ElasticSearch/AggregationRelation)
for a complete API reference.

### Suggestions

```ruby
query = CommentIndex.suggest(:suggestion, text: "helo", term: { field: "message" })
query.suggestions(:suggestion).first["text"] # => "hello"
```

### Highlighting

```ruby
CommentIndex.highlight([:title, :message])
CommentIndex.highlight(:title).highlight(:description)
CommentIndex.highlight(:title, require_field_match: false)
CommentIndex.highlight(title: { type: "fvh" })
```

```ruby
query = CommentIndex.highlight(:title).search("hello")
query.results[0].highlight.title # => "<em>hello</em> world"
```

### Advanced Relation Methods

There are even more methods to make your life easier, namely `source`,
`scroll`, `profile`, `includes`, `preload`, `find_in_batches`, `find_each` and
`failsafe` to name just a few:

* `source`

In case you want to restrict the returned fields, simply specify
the fields via `#source`:

```ruby
CommentIndex.source([:id, :message]).search("hello world")
```

* `paginate`, `page`, `per`

The ElasticSearch gem supports will_paginate and kaminari compatible pagination.
Thus, you can either use `#paginate` or `#page` in combination with `#per`:

```ruby
CommentIndex.paginate(page: 3, per_page: 50)
CommentIndex.page(3).per(50)
```

* `scroll`

You can as well use the underlying scroll API directly, ie. without using higher
level pagination:

```ruby
query = CommentIndex.scroll(timeout: "5m")

until query.records.empty?
  # ...

  query = query.scroll(id: query.scroll_id, timeout: "5m")
end
```

* `profile`

To enable query profiling simply use:

Use `#profile` To enable query profiling:

```ruby
query = CommentIndex.profile(true)
query.raw_response["profile"] # => { "shards" => ... }
```

* `preload`, `eager_load` and `includes`

Uses the well known methods from ActiveRecord to load
associated database records when fetching the respective
records themselves. Works with other ORMs as well, if
supported.

Using `#preload`:

```ruby
CommentIndex.preload(:user, :post).records
PostIndex.includes(:comments => :user).records
```

or `#eager_load`

```ruby
CommentIndex.eager_load(:user, :post).records
PostIndex.eager_load(:comments => :user).records
```

or `#includes`

```ruby
CommentIndex.includes(:user, :post).records
PostIndex.includes(:comments => :user).records
```

* `find_in_batches`

Used to fetch and yield records in batches using the ElasicSearch scroll API.
The batch size and scroll API timeout can be specified.

```ruby
CommentIndex.search("hello world").find_in_batches(batch_size: 100) do |batch|
  # ...
end
```

* `find_each`

Like `#find_in_batches`, used `#find_each` to fetch records in batches, but yields
one one record at a time.

```ruby
CommentIndex.search("hello world").find_each(batch_size: 100) do |record|
  # ...
end
```

* `failsafe`

Use `#failsafe` to prevent any exceptions from being raised for query string syntax
errors or ElasticSearch being unavailable, etc.

```ruby
CommentIndex.search("invalid/request").execute
# raises RestClient::BadRequest: 400 Bad Request

# ...

CommentIndex.search("invalid/request").failsafe(true).execute
# => #<ElasticSearch::Response ...>
```

For a full list of methods, check out the reference docs.

## Non-ActiveRecord models

The ElasticSearch gem ships with built-in support for ActiveRecord models, but
using non-ActiveRecord models is very easy. The model must implement a
`find_each` class method and the Index class needs to implement
`Index.record_id` and `Index.fetch_records`. The default implementations for
the index class are as follows:

```ruby
class MyIndex
  include ElasticSearch::Index

  def self.record_id(object)
    object.id
  end

  def self.fetch_records(ids)
    model.where(id: ids)
  end
end
```

Thus, simply add your custom implementation of those methods that work with
whatever ORM you use.

## Feature Support

`#post_search` and `#profile` are only supported from up to ElasticSearch
Server version >= 2.

## TODO

Things on the To do list before releasing it:

1. Check if gem name is allowed
2. Add convenience mixin for re-indexing ActiveRecord models on callbacks
3. Switch to httpary or http-rb and use custom exceptions
4. First class support for `nested`, `has_parent` and `has_child` queries
5. Support collapse

## Links

* ElasticSearch Server: [https://www.elastic.co/](https://www.elastic.co/)
* Reference Docs: [http://www.rubydoc.info/github/mrkamel/elastic_search](http://www.rubydoc.info/github/mrkamel/elastic_search)
* Travis: [http://travis-ci.org/mrkamel/elastic_search](http://travis-ci.org/mrkamel/elastic_search)

