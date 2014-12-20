# Squares \[\*\]

Lightweight ORM backed by any hash-like storage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'squares'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install squares

## Usage

# Models

```ruby
class Person < Squares::Base

properties :real_name, :age

end
```

# Bootstrapping

Then bootstrap those models to storage objects (in this case LevelDB) like so:

```ruby
Squares.storage_for([Person, Place, Thing]) do |model|
  LevelDB::DB.new "./tmp/#{model.underscore_name}"
end
```

...or if you want to use plain ole hashes:

```ruby
Squares.storage_for([Person,Place,Thing]) { Hash.new }
```

# And Then Fun

Squares does not auto-generate an `:id` for each new object --you'll do that
and it will be used as the "key" in the hash storage.  In the following example,
we're creating a new `Person` and using 'spiderman' as the key:

```ruby
pete = Person.new('spiderman', real_name: 'Peter Parker', age: 17)
pete.save

Person.has_key? 'spiderman' #=> true
pete.id                     #=> 'spiderman'
```

When we retrieve an object, it returns us an instance of that model:

```ruby
wallcrawler = Person['spiderman']
wallcrawler = Person.find 'spiderman' #=> same, shmame.
wallcrawler.id                        #=> 'spiderman'
wallcrawler.real_name                 #=> 'Peter Parker'
wallcrawler.class                     #=> Person
```

Of course, for some types of storage, the model object has to be serialized and
de-serialized when it's stored and retrieved.  Squares uses `Marshal.dump` and
`Marshal.restore` to do that.  This means that custom marshalling can be added
to your models (see [documentation on ruby Marshal](http://www.ruby-doc.org/core-2.1.5/Marshal.html)).

## Contributing

1. Fork it ( https://github.com/joelhelbling/squares/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
