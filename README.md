[![Rspec](https://github.com/verse-rb/verse-core/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/verse-rb/verse-core/actions/workflows/main.yml)

# Verse::Core

Welcome to `Verse::Core`, the foundation of the Verse framework.

Verse is a modern Ruby framework for building event-driven microservices. It's designed to be lightweight, fast, and modular, allowing you to build scalable and maintainable applications with ease.

## Core Concepts

Verse is built around a 3-tiered architecture:

1.  **Exposition Layer**: This is the entry point to your application. It handles incoming requests, whether they are HTTP calls, events from a message bus, or scheduled tasks. The exposition layer is responsible for validating input, and passing it to the service layer.

2.  **Service Layer**: This layer contains the business logic of your application. Services are plain Ruby objects that orchestrate the work to be done. They are completely decoupled from the transport layer, making them easy to test and reuse.

3.  **Model Layer**: This layer is responsible for data persistence and retrieval. It includes repositories and records, which provide an abstraction over your database or other data stores. The model layer is also where you define your authorization rules.

Here's an example of how these layers work together:

```ruby
# Exposition Layer
class MyExposition < Verse::Expo::Base
  use_service MyService

  # from verse-http plugin
  expose on_http(:get, "/users/:id") do
    input { field(:id, Integer).filled }
  end
  def get_user
    service.find(params[:id])
  end
end

# Service Layer
class MyService < Verse::Service::Base
  use_repo MyRepo

  def find(id)
    repo.find(id)
  end
end

# Model Layer (using verse-sequel plugin)
class MyRepo < Verse::Sequel::Repository
  self.table = "users"
  self.model_class = UserRecord
end

class UserRecord < Verse::Model::Record::Base
    field :id, type: Integer, primary: true
    field :name, type: String
end
```

## Features

`Verse::Core` provides a solid foundation for building your microservices. Here are some of the key features:

*   **Plugin System**: Verse is highly modular. You can extend its functionality with plugins for things like HTTP servers, database adapters, and more.
*   **Authentication and Authorization**: A robust authentication and authorization system with a flexible role-based access control model.
*   **Caching**: A simple caching API with a default in-memory adapter.
*   **Distributed Primitives**: In-memory implementations of distributed primitives like locks, counters, and key-value stores.
*   **Event System**: A powerful event system that allows you to build event-driven architectures.
*   **Schema Validation**: A simple and powerful schema validation library for your inputs.

## Universe Plugins

The Verse team maintains a collection of official plugins called the "Universe". These plugins provide additional functionality and integrations with popular libraries.

| Name                                                       | Status      | Description                                            |
| ---------------------------------------------------------- | ----------- | ------------------------------------------------------ |
| [verse-http](https://github.com/verse-rb/verse-http)       | Ready       | Sinatra based HTTP server                              |
| [verse-jsonapi](https://github.com/verse-rb/verse-jsonapi) | Ready       | JSON::Api renderer for your API                        |
| [verse-jsonrpc](https://github.com/verse-rb/verse-jsonrpc) | Ready       | Json RPC renderer for your API                         |
| [verse-login](https://github.com/verse-rb/verse-login)     | Ready       | JWT authorization implementation                     |
| [verse-otelemetry](https://github.com/verse-rb/verse-otelemetry) | Planned | open telemetry integration |
| [verse-periodic](https://github.com/verse-rb/verse-periodic) | Ready       | CRON and repeatable tasks                              |
| [verse-redis](https://github.com/verse-rb/verse-redis)     | Ready       | Redis integration to Verse                             |
| [verse-saga](https://github.com/verse-rb/verse-saga) | Planned | Job and Saga management |
| [verse-schema](https://github.com/verse-rb/verse-schema)   | Ready       | Schema validation for inputs                           |
| [verse-sequel](https://github.com/verse-rb/verse-sequel)   | Ready       | Repositories implementation using the Sequel gem.      |
| [verse-shrine](https://github.com/verse-rb/verse-shrine)   | Ready       | File storage using the Shrine gem.                     |


## Getting Started

To install `verse-core`, add it to your application's Gemfile:

```ruby
gem "verse-core"
```

Then, run `bundle install`.

For a complete example of how to build a simple application with Verse, check out the [Getting Started Guide](./manual/getting_started.md).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/verse-rb/verse-core.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
