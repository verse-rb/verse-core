[![Rspec](https://github.com/verse-rb/verse-core/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/verse-rb/verse-core/actions/workflows/main.yml)

# Verse

Welcome to Verse.

Verse is a framework made for Event Driven Microservice Architecture (EDMA).
We haven't found any framework in Ruby, so we've made one !

With Verse, you can quickly design, implement and deploy web applications,
scaling

Verse is an opinionated microframework.

It is a microframework, as it requires very few dependencies and provides the
bare minimum.
By default, Verse will require `verse-schema`.

Compared to Rails, your application will boot extremely fast, and the scope pollution (e.g. monkey patching & method definition) is minimal.

Verse is a 3-tiered architecture:
1. Exposition Layer
2. Service Layer
3. Model Layer

## Exposition layer

Exposition layer is in charge of exposing your service to the "world".
The world is made of HTTP queries, events you receive from the event bus periodic Cron job or other events.

The role of the exposition layer is to:
- Declare what you are listening to.
- Reject ill-formated inputs
- Filter the noise, by removing useless informations.
- Define output format and/or used renderer.

An example of exposition (using [UniVerse plugins](#universe-plugins))

```ruby
class MyExposition < Verse::Expo::Base
    use_service MyService

    # hook the web (from verse-http plugin)
    expose on_http(:get, "/endpoint") do
        desc "this will listen to HTTP GET over /endpoint"
        input do
            field(:id, Integer).filled
        end
    end
    def do_something
        service.do_something(params[:id])
    end

    # hook the time (from verse-periodic plugin)
    expose on_schedule("5 4 * * *") do
        desc "Every day at 4:05. Will run once per service (not per instance!)"
    end
    def on_schedule
        service.perform_maintenance_task!
    end

    # hook the event bus
    expose on_event("other_service.form.sent") do
        input do
            field(:id, Integer).filled
            field(:email, String).filled
        end
    end
    def on_form_edited
        service.thank_customer(params[:id])
    end
end
```

The service layer is in charge of dealing with the business logic of your information.
Basically, this layer is open to interpretation for each developer. Create and maintain services objects. One good practice is to completely ignore technical issues/details and focus on the business part of your application here.


```ruby
class MyService < Verse::Service::Base
    def thank_customer(form_id, email)
        Email.new(email: email).send
        Verse.publish("customer.thanked", {email: email})
    end
end
```

Finally, the model layer is in charge of applying effects.
By effect, we mean operations that would transform/create data in your system.
This includes any access to the database, file storage, or any 3rd party API call.
In Verse, anything related to authorization is made at the model level.
Unlike many frameworks, you won't define authorization at the controller level (e.g., can access this specific endpoint). Instead, you will work with our powerful Auth Context system (as a _role_, I have _action_ access to a subset (_scope_) of _resources_).

## What contains Verse Core exactly?

Not much. Verse-core doesn't even have an HTTP server by default!
Verse has been built with modularity in mind and offers a simple and powerful plugin system.
Running bare-minimum Verse won't get you very far, but check the [Getting started](./manual/getting_started.md) page for how to set up a quick project using `verse-http`, `verse-sequel` and `verse-redis` (for event-bus)!

With verse-core, you will get access to:
- Service lifecycle management.
- Foundations for each layer (Exposition, Service, Model).
- Authentication and Authorization system (`Verse::Auth`).
- Caching (`Verse::Cache`) with a default in-memory adapter.
- Distributed primitives (`Verse::Distributed`) like Lock, Counter, and KV Store, with default in-memory implementations.
- A standard set of errors for common scenarios (`Verse::Error`).
- Foundational modules for specs and generators.
- Abstract classes for Repository and Record access.
- Event publishing system. An adapter is required for message transport (e.g., `verse-redis`).

## UniVerse plugins

Those plugins are maintained by the Verse development team.

Name | Status | Description |
|----------|----------|-----------|
| [verse-http](https://github.com/verse-rb/verse-http) | Ready | Sinatra based HTTP server |
| [verse-jsonapi](https://github.com/verse-rb/verse-jsonapi) | Ready | JSON::Api renderer for your API |
| [verse-jsonrpc](https://github.com/verse-rb/verse-jsonrpc) | Ready | Json RPC renderer for your API |
| [verse-login](https://github.com/verse-rb/verse-login) | Ready | JWT authorization implementation |
| [verse-otelemetry](https://github.com/verse-rb/verse-otelemetry) | Planned | open telemetry integration |
| [verse-periodic](https://github.com/verse-rb/verse-periodic) | Ready | CRON and repeatable tasks |
| [verse-redis](https://github.com/verse-rb/verse-redis) | Ready | Redis integration to Verse |
| [verse-saga](https://github.com/verse-rb/verse-saga) | Planned | Job and Saga management |
| [verse-schema](https://github.com/verse-rb/verse-schema) | Ready | Schema validation for inputs |
| [verse-sequel](https://github.com/verse-rb/verse-sequel) | Ready | Repositories implementation using the Sequel gem. |
| [verse-shrine](https://github.com/verse-rb/verse-shrine) | Ready | File storage using the Shrine gem. |

## MultiVerse Plugins

Here you will find the plugins managed by authors different from the Verse team.
Verse is quite new. We are waiting for some developers to join the multi-verse!

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add verse-core

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install verse-core

## Usage

To setup a quick HTTP application, you can use the `verse` command-line tool, which is available when you install the `verse-cli` gem.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/verse-rb/verse-core.

## License

Released under the MIT license.

Copyright, 2023, by Yacine Petitprez.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
