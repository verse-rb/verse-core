[![Rspec](https://github.com/verse-rb/verse-core/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/verse-rb/verse-core/actions/workflows/main.yml)

# Verse

Welcome to Verse.

Verse is a framework made for Event Driven Microservice Architecture (EDMA).
We haven't found any framework in Ruby, so we've made one !

With Verse, you can quickly design, implement and deploy web applications,
scaling

Verse is an opiniated microframework.

It is a microframework, as it requires very little dependencies and provide the
bare minimum.
By default, Verse will require `dry` gems, `i18n` and `thor` (for CLI usage only).

Compared to Rails, your application will boot extremely fast, and the scope pollution (e.g. monkey patching & method definition) is minimal.

Verse is 3 tiered architecture:
1. Exposition Layer
2. Service Layer
3. Effect Layer

## Exposition layer

Exposition layer is in charge of exposing your service to the "world".
The world is made of HTTP queries, events you receive from the event bus periodic Cron job or other events.

The role of the exposition layer is to:
- Declare what you are listening to.
- Reject ill-formated inputs
- Filter the noise, by removing useless informations.
- Define output format and/or used renderer.

An example of exposition (using [universe plugins](#universe-plugins))

```ruby
class MyExposition < Verse::Expo::Base
    use_service MyService

    # hook the web
    expose on_http(:get, "/endpoint") do
        desc "this will listen to HTTP GET over /endpoint"
        input do
            required(:id).filled(:integer)
        end
    end
    def do_something
        service.do_something(params[:id])
    end

    # hook the time
    expose on_cron("5 4 * * *") do
        desc "Every day at 4:05. Will run once per service (not per instance!)"
    end
    def on_cron
        service.perform_maintenance_task!
    end

    # hook the event bus
    expose on_event("other_service.form.sent") do
        input do
            required(:id).filled(:integer)
            required(:email).filled(:string)
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

Finally, the effect layer is in charge of applying effect.
By effect, we mean operations that would transform/create data in your system.
So any access to the database, any file storage or any 3rd party API call.
Please note that in verse, anything related to the authorization is made at effect level.
Unlike many software, you won't define authorization at the controller level (e.g. can access this specific endpoint) but, instead you will work with our powerful Auth Context system (as _role_, I have _action_ access to a subset (_scope_) of _resources_ )

## What contains Verse Core exactly?

Not much. Verse-core doesn't even have an HTTP server by default!
Verse has been built with modularity in mind, and offers a simple and powerful plugin system.
Running bare-minimum Verse won't get you very far, but check the [Getting started](./manual/getting_started.md) page for how to setup a quick project using verse-sinatra, verse-sequel and verse-nats !

With verse-core, you will get access to:
- Service lifecycle
- Foundation for each layers
- Foundation for side stuff like specs and generator
- Some abstract classes for Repository and Record access
- Publish to event bus. Need an adapter (currently NATS is supported)

## UniVerse plugins

Those plugins are maintained by the Verse development team.

Name | Description |
---------|----------|
 verse-apm | ELK APM integration for Verse |
 verse-auth | JWT authorization implementation |
 verse-csv | A CSV renderer for verse-http using streaming capabilities |
 verse-discovery | Command between services |
 verse-execute | At runtime remote code execution |
 verse-http | Sinatra based HTTP server |
 verse-instrument | instrumentation endpoints for your services |
 verse-jsonapi | JSON::Api renderer for your API |
 verse-mongo | Repositories implementation for mongodb |
 verse-nats | Event Bus implementation using NATS as backend |
 verse-periodic | CRON and repeatable tasks |
 verse-redis | Redis integration to Verse |
 verse-sentry | Integration with Sentry.io bug tracking |
 verse-sequel | Repositories implementation using the Sequel gem. |
 verse-shrine | File storage using the Shrine gem. |
 verse-email | Email effect layer |
 verse-saga | Saga management and Jobs made for Verse |

## MultiVerse Plugins

Here you will find the plugins managed by authors different from the Verse team.
Verse is quite new. We are waiting for some developers to join the multi-verse!

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add verse-core

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install verse-core

## Usage

Get access to the CLI by calling:

```
verse --help
```

To setup a quick HTTP application:

```
verse g new --plugins=http,nats,sequel
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/verse-core.

## License

Released under the MIT license.

Copyright, 2023, by Yacine Petitprez.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.