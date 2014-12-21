# Squares \[\*\]

A lightweight ORM backed by any hash-like storage.  Hand-crafted from a solid piece of pure
aircraft-grade Ruby and drawing distilled awesomeness from atmospheric pollutants, its only
dependency is you.

## Installation Blah, Blah, Blah

_I swear, this part of the README just rolled right out of `bundle gem squares`._

Add this line to your application's Gemfile:

```ruby
gem 'squares'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install squares

_And yeah, I did enjoy typing `bundle gem squares`.  It sounds like something to
eat.  Now I'm hungry._

## Usage

_Because you are going to use it._

```ruby
require 'squares'
```

### Write Models

_How come they never write back?_

```ruby
class Person < Squares::Base
  properties :real_name, :age
end
```

You can also provide a default value if you switch to the `property` variant:

```ruby
class Person < Squares::Base
  property :eye_color, default: 'brown'
end
```

### Bootstrapping

_A funny word for "setup & configure".  Bootstrapping.  Bootstrapping.  See?  Funny._

Now you can bootstrap `;)` your model to a hash-like storage object like so:

```ruby
people_storage = Redis::Namespace.new(
                   Person.underscore_name,
                   :redis => $redis_connection )

Person.store = people_storage
```

Or if you just want to use a plain ole in-memory hash:

```ruby
tom_sellecks_mustache = {}
Soup.store = tom_sellecks_mustache
```

Squares actually defaults the store to an empty hash, which means if you're ok
with in-memory, transient storage (e.g. when writing tests, etc.) you don't have
to do any config-- er, bootstrapping `;)` at all!

You can setup a bunch of 'em like this:

```ruby
[Person, Place, SwampThing].each do |model|
  model.store = LevelDB::DB.new("./tmp/#{model.underscore_name}")
end
```

But it gets even better: the Squares module is an `Enumerable` which enumerates all
the model classes (inheritors of `Squares::Base`).  So you can:

```ruby
Squares.map &:underscore_name #=> ['person', 'place', 'swamp_thing']
```

Or better yet:

```ruby
Squares.each do |model|
  model.store = LevelDB::DB.new './tmp/#{model.underscore_name}'
end
```

### Onward To The Fun

Squares does not auto-generate an `:id` for each new object --you'll do that
and it will be used as the "key" in the hash storage.  In the following example,
we're creating a new `Person` and using 'spiderman' as the key:

```ruby
pete = Person.new('spiderman', real_name: 'Peter Parker', age: 17)
#                 ^^^ key ^^^  ^^^^^^^^^^^ properties ^^^^^^^^^^^
pete.save

Person.has_key? 'spiderman' #=> true
pete.id                     #=> 'spiderman'
```

When we retrieve an object, it returns an instance of that model:

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
to your models (see [documentation on ruby Marshal][marshal]).

### Even More Fun

You can use the ActiveRecord-esque `.where` method with a block to retrieve records
for which the block returns true:

```ruby
Person.where { |p| p.left_handed == true } #=> all the lefties
```

The `.where` method is actually just an alias of `.select`...which means, yeah!
Squares are enumerable, yay!

```ruby
Person.map(&:name) #=> an array containing all the names
```

### What It Doesn't Do

Much like Wolverine, Squares doesn't do relationships.  You'll have to
maintain those in your code.  If you have an issue with that, leave me
an issue, and I'll think about what that might mean.

Squares neither knows nor cares about the type or contents of your model
instance's properties.  This has consequences.

First, anything you stash had darn well better be marshal-able, or there
will be blood on the roller-rink.  Or at least errors.  Yeah, I've made
sure there won't be blood (you're welcome), but watch out for errors.
If you run into problems, refer to the [documentation on ruby Marshal][marshal].

Second, there is no magic-fu for stuff like generating question methods
for boolean properties.  For example, it doesn't make a `#left_handed?` method
out of your `property :left_handed`).  But hey, you know what you can
do?  Behold:

```ruby
class Person
  property :awesome?, default: true #=> What?! is that a "?"
end
```

Ok, don't interrupt me, I'm selling here...

```ruby
you = Person.new
you.awesome? #=> true
```

Of course, Squares doesn't mind how you use `#awesome?` and the corresponding `#awesome=` methods:

```ruby
you.awesome = 'yak hair'
you.awesome? #=> 'yak hair'
```

or

```ruby
you.awesome = nil
you.awesome? #=> nil
```

But hey, who cares, as long as yak hair is truthy?

[marshal]:http://www.ruby-doc.org/core-2.1.5/Marshal.html

## Contributing

1. Fork it ( https://github.com/joelhelbling/squares/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
