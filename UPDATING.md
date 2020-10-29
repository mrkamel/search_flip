
# Updating from previous SearchFlip versions

## Update 3.x to 4.x

**[BREAKING]** For performance reasons, `SearchFlip::Result` no longer
inherits `Hashie::Mash`

* It no longer supports symbol based access like `result[:id]`

2.x:

```ruby
CommentIndex.match_all.results.first[:id]
CommentIndex.aggregate(:tags).aggregations(:tags).values.first[:doc_count]
```

3.x

```ruby
CommentIndex.match_all.results.first["id"] # or .id
CommentIndex.aggregate(:tags).aggregations(:tags).values.first["doc_count"] # or .doc_count
```

* It no longer supports question mark methods like `result.title?`

2.x:

```ruby
CommentIndex.match_all.results.first.is_published?
```

3.x

```ruby
CommentIndex.match_all.results.first.is_published == true
```

* It no longer supports method based assignment like `result.some_key = "value"`.

However, this should not have any practical implications, as changing the
results is not considered to be a common use case.

## Update 2.x to 3.x

* **[BREAKING]**  No longer pass multiple arguments to `#must`, `#must_not`,
  `#filter`, `#should`, `#post_must`, `#post_must_not`, `#post_filter`, and
  `#post_should`.

2.x:

```ruby
CommentIndex.must({ term: { state: "new" } }, { term: { state: "approved" } })
```

3.x:

```ruby
CommentIndex.must([
  { term: { state: "new" } },
  { term: { state: "approved" } }
])
```

Same for `#must_not`, `#filter`, `#should`, etc.

* **[BREAKING]** `#should` and `#post_should` is now equivalent to `.must(bool: {
  should: ... })` and `.post_must(bool: { should: ... })`, respectively.

No necessary code changes, but different queries will be produced:

2.x:

```ruby
query = CommentIndex.should([
  { term: { state: "new" } },
  { term: { state: "approved" }}
])

query = query.should([
  { term: { state: "declined" } },
  { term: { state: "pending" } }
])
```

generated a query matching:

`new OR approved OR declined OR pending`

3.x:

SearchFlip 3 generates a query matching:

`(new OR approved) AND (declined OR pending)`

as desired in nearly all cases.

* [BREAKING] `#unscope` is removed

There is no equivalent replacement, but you can achieve the same by using the
intermediate queries instead:

2.x:

```ruby
query1 = CommentIndex.where(price: 0..20).search("some terms")
query2 = query1.unscope(:search)
```

3.x

```ruby
query1 = CommentIndex.where(price: 0..20)
query2 = query1.search("some terms")
```

* **[BREAKING]** `SearchFlip::Connection#get_aliases` no longer returns a
  Hashie::Mash, but a raw Hash as was already stated in the docs

Code changes are only neccessary if you use methods related to `Hashie::Mash`
on the result of `#get_aliases` like e.g.

2.x:

```ruby
CommentIndex.connection.get_aliases['index_name'].aliases
```

3.x:

```ruby
CommentIndex.connection.get_aliases['index_name']['aliases']
```

## Update 1.x to 2.x

* **[BREAKING]** No longer include the `type_name` in `SearchFlip::Index.mapping`

1.x:

```ruby
class MyIndex
  include SearchFlip::Index

  # ...

  def self.mapping
    {
      type_name: {
        properties: {
          # ...
        }
      }
    }
  end
end
```

2.x:

```ruby
class MyIndex
  include SearchFlip::Index

  # ...

  def self.mapping
    {
      properties: {
        # ...
      }
    }
  end
end
```

* **[BREAKING]** Changed `SearchFlip::Index.base_url` to `SearchFlip::Index.connection`

1.x:

```ruby
class MyIndex
  include SearchFlip::Index

  # ...

  def self.base_url
    "..."
  end
end
```

2.x:

```ruby
class MyIndex
  include SearchFlip::Index

  # ...

  def self connection
    @connection ||= SearchFlip::Connection.new(base_url: "...")
  end
end
```

* **[BREAKING]** Changed `SearchFlip.version` to `SearchFlip::Connection#version`

1.x:

```ruby
SearchFlip.version
```

2.x:

```ruby
MyIndex.connection.version

# or

connection = SearchFlip::Connection.new(base_url: "...")
connection.version
```

* **[BREAKING]** Changed `SearchFlip.aliases` to `SearchFlip::Connection#update_aliases`

1.x:

```ruby
SearchFlip.aliases(actions: [
  # ...
])
```

2.x:

```ruby
MyIndex.connection.update_aliases(actions: [
  # ...
])

# or

connection = SearchFlip::Connection.new(base_url: "...")
connection.update_aliases(actions: [
  # ...
])
```

* **[BREAKING]** Changed `SearchFlip.msearch` to `SearchFlip::Connection#msearch`

1.x:

```ruby
SearchFlip.msearch(queries)
```

2.x:

```ruby
MyIndex.connection.msearch(queries)

# or

connection = SearchFlip::Connection.new(base_url: "...")
connection.msearch(queries)
```

* **[BREAKING]** Removed `base_url` param from `SearchFlip::Critiera#execute`

1.x:

```ruby
MyIndex.where(id: 1).execute(base_url: "...")
```

2.x:

```ruby
connection = SearchFlip::Connection.new(base_url: "...")
MyIndex.where(id: 1).with_settings(connection: connection).execute
```

* **[BREAKING]** Move hit data within results in `_hit` namespace

1.x:

```ruby
query = CommentIndex.highlight(:title).search("hello")
query.results[0].highlight.title # => "<em>hello</em> world"
```

2.x:

```ruby
query = CommentIndex.highlight(:title).search("hello")
query.results[0]._hit.highlight.title # => "<em>hello</em> world"
```

* **[BREAKING]** `index_name` no longer defaults to `type_name`

1.x:

```ruby
class CommentIndex
  include SearchFlip::Index

  def self.type_name
    "comments"
  end

  # CommentIndex.index_name defaults to CommentIndex.type_name
end
```

2.x:

```ruby
class CommentIndex
  include SearchFlip::Index

  def self.type_name
    "comments"
  end

  def self.index_name
    "comments"
  end
end
```

* **[BREAKING]** Multiple calls to `source` no longer concatenate

1.x:

```ruby
CommentIndex.source([:id]).source([:description]) # => CommentIndex.source([:id, :description])
```

2.x:

```ruby
CommentIndex.source([:id]).source([:description]) # => CommentIndex.source([:description])
```
