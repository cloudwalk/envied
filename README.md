# ENVied [![Build Status](https://travis-ci.org/eval/envied.svg?branch=master)](https://travis-ci.org/eval/envied) [![project chat](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://envied-rb.zulipchat.com/)

### TL;DR ensure presence and type of your app's ENV-variables.

For the rationale behind this project, see this [blogpost](http://www.gertgoet.com/2014/10/14/envied-or-how-i-stopped-worrying-about-ruby-s-env.html).

## Features:

* check for presence and correctness of ENV-variables
* access to typed ENV-variables (integers, booleans etc. instead of just strings)

## Contents

* [Quickstart](#quickstart)
* [Installation](#installation)
* [Configuration](#configuration)
  * [Types](#types)
  * [Groups](#groups)
  * [Defaults](#defaults)
  * [More examples](#more-examples)
* [Testing](#testing)
* [Developing](#developing)

## Quickstart

### 1) Configure

After [successful installation](#installation), define some variables in `Envfile`:

```ruby
# file: Envfile
variable :FORCE_SSL, :boolean
variable :PORT, :integer
```

### 2) Check for presence and coercibility

```ruby
# during initialization
ENVied.require
```

This will throw an error if:
* both `ENV['FORCE_SSL']` and `ENV['PORT']` are *not present*.
* the values *cannot* be coerced to a boolean and integer.

### 3) Use coerced variables

Variables accessed via ENVied are of the correct type:

```ruby
ENVied.PORT # => 3001
ENVied.FORCE_SSL # => false
```

## Installation

Add this line to your application's Gemfile:

    gem 'envied'

...then bundle:

    $ bundle

## Configuration

### Types

The following types are supported:

* `:string` (implied)
* `:boolean` (e.g. '0'/'1', 'f'/'t', 'false'/'true', 'off'/'on', 'no'/'yes' for resp. false and true)
* `:integer`
* `:float`
* `:json`
* `:symbol`
* `:date` (e.g. '2014-3-26')
* `:time` (e.g. '14:00')
* `:hash` (e.g. 'a=1&b=2' becomes `{'a' => '1', 'b' => '2'}`)
* `:array` (e.g. 'tag1,tag2' becomes `['tag1', 'tag2']`)
* `:uri` (e.g. 'http://www.google.com' becomes result of `URI.parse('http://www.google.com')`)
* `:uuid`

### Groups

Groups give you more flexibility to define when variables are needed.
It's similar to groups in a Gemfile:

```ruby
# file: Envfile
variable :FORCE_SSL, :boolean, default: 'false'

group :production do
  variable :SECRET_KEY_BASE
end

group :development, :staging do
  variable :DEV_KEY
end
```

```ruby
# For local development you would typically do:
ENVied.require(:default) #=> Only ENV['FORCE_SSL'] is required
# On the production server:
ENVied.require(:default, :production) #=> ...also ENV['SECRET_KEY_BASE'] is required

# You can also pass it a string with the groups separated by comma's:
ENVied.require('default, production')

# This allows for easily requiring groups using the ENV:
ENVied.require(ENV['ENVIED_GROUPS'])
# ...then from the prompt:
$ ENVIED_GROUPS='default,production' bin/rails server

# BTW the following are equivalent:
ENVied.require
ENVied.require(:default)
ENVied.require('default')
ENVied.require(nil)
```

### Defaults

In order to let other developers easily bootstrap the application, you can assign defaults to variables.
Defaults can be a value or a `Proc` (see example below).

Note that 'easily bootstrap' is quite the opposite of 'fail-fast when not all ENV-variables are present'. Therefore you should explicitly state when defaults are allowed:

```ruby
# Envfile
enable_defaults! { ENV['RACK_ENV'] == 'development' }

variable :FORCE_SSL, :boolean, default: 'false'
variable :PORT, :integer, default: proc {|envied| envied.FORCE_SSL ? 443 : 80 }
```

Please remember that ENVied only **reads** from ENV; it doesn't mutate ENV.
Don't let setting a default for, say `RAILS_ENV`, give you the impression that `ENV['RAILS_ENV']` is set.
As a rule of thumb you should only use defaults:
* for local development
* for ENV-variables that are solely used by your application (i.e. for `ENV['STAFF_EMAILS']`, not for `ENV['RAILS_ENV']`)

### More examples

* See the [examples](/examples)-folder for a more extensive Envfile
* See [the Envfile](https://github.com/eval/bunny_drain/blob/c54d7d977afb5e23a92da7a2fd0d39f6a7e29bf1/Envfile) for the bunny_drain application

## Testing

```bash
bundle install
RUBYOPT="-W:deprecated" bundle exec rspec
```

## Developing

```bash
bin/console
```
