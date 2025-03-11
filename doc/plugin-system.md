# Plugin System

The plugin system is a core component of the Verse framework, enabling extensibility through plugins. This document explains how the plugin system works and how to use it.

## Overview

The plugin system in Verse Core allows extending the framework with additional functionality. Plugins can:

- Add new capabilities to the framework
- Integrate with external systems
- Modify the behavior of existing components
- Provide new implementations of core interfaces

## Plugin Base Class

All plugins in Verse Core inherit from `Verse::Plugin::Base`, which provides common functionality:

```ruby
module Verse
  module MyPlugin
    class Plugin < Verse::Plugin::Base
      # Plugin implementation
    end
  end
end
```

## Plugin Lifecycle

Plugins have a well-defined lifecycle with several hooks:

| Lifecycle Hook | Description | When Called |
|----------------|-------------|-------------|
| `initialize` | Initialize the plugin | When the plugin is loaded |
| `on_init` | Initialize dependencies | After all plugins are loaded |
| `on_start` | Start the plugin | When the server starts |
| `on_stop` | Stop the plugin | When the server stops |
| `on_finalize` | Clean up resources | Final step of shutdown |

Example:

```ruby
module Verse
  module MyPlugin
    class Plugin < Verse::Plugin::Base
      def on_init
        # Initialize dependencies
      end

      def on_start(mode)
        # Start the plugin
        # mode can be :server, :spec, :rake, :console
      end

      def on_stop
        # Stop the plugin
      end

      def on_finalize
        # Clean up resources
      end
    end
  end
end
```

## Plugin Dependencies

Plugins can declare dependencies on other plugins:

```ruby
module Verse
  module MyPlugin
    class Plugin < Verse::Plugin::Base
      def dependencies
        [:redis, :sequel]
      end

      def on_init
        # Access dependencies
        redis.client
        sequel.connection
      end
    end
  end
end
```

Dependencies are automatically initialized and made available as methods on the plugin instance.

## Plugin Configuration

Plugins can receive configuration from the Verse configuration system:

```ruby
# In configuration
Verse::Config.config = {
  plugins: [
    {
      name: "my_plugin",
      config: {
        url: "https://example.com",
        timeout: 30
      }
    }
  ]
}

# In the plugin
module Verse
  module MyPlugin
    class Plugin < Verse::Plugin::Base
      def on_init
        # Access configuration
        url = config[:url]
        timeout = config[:timeout]
      end
    end
  end
end
```

## Plugin Registration

Plugins are registered with the Verse framework through the configuration system:

```ruby
Verse::Config.config = {
  plugins: [
    {
      name: "redis",
      plugin: "redis",
      config: {
        url: "redis://localhost:6379/0"
      }
    },
    {
      name: "sequel",
      plugin: "sequel",
      config: {
        url: "postgres://localhost/myapp"
      },
      mapping: {
        db: "sequel" # Map `db` dependency to sequel plugin
      }
    }
  ]
}
```

The `name` is the identifier for the plugin, and the `plugin` is the name of the plugin class (or a Ruby class).

## Dependency Mapping

Plugins can map dependencies to other plugins:

```ruby
Verse::Config.config = {
  plugins: [
    {
      name: "my_plugin",
      plugin: "my_plugin",
      mapping: {
        db: "sequel" # Map `db` dependency to sequel plugin
      }
    }
  ]
}
```

This allows plugins to refer to dependencies by logical names rather than specific implementations.

## Accessing Plugins

Plugins can be accessed through the `Verse::Plugin` module:

```ruby
# Get a plugin by name
redis_plugin = Verse::Plugin[:redis]

# Check if a plugin exists
if Verse::Plugin.exists?(:redis)
  # Use the plugin
end

# Get all plugins
all_plugins = Verse::Plugin.all
```

## Creating a Plugin

To create a plugin:

1. Create a gem with the naming convention `verse-<plugin_name>`
2. Define a plugin class in the `Verse::<PluginName>::Plugin` namespace
3. Implement the plugin lifecycle hooks
4. Register the plugin in the Verse configuration

Example:

```ruby
# In verse-redis/lib/verse/redis/plugin.rb
module Verse
  module Redis
    class Plugin < Verse::Plugin::Base
      def on_init
        # Initialize Redis connection
        @client = ::Redis.new(config)
      end

      def on_start(mode)
        # Start the plugin
      end

      def on_stop
        # Stop the plugin
        @client.close
      end

      def client
        @client
      end
    end
  end
end

# In verse-redis.gemspec
Gem::Specification.new do |spec|
  spec.name          = "verse-redis"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.summary       = "Redis plugin for Verse"

  spec.add_dependency "verse-core", "~> 0.1"
  spec.add_dependency "redis", "~> 4.0"
end
```

## Plugin Types

Verse Core supports several types of plugins:

### Event Manager Plugins

Event manager plugins provide implementations of the event manager interface:

```ruby
module Verse
  module Redis
    module Stream
      class EventManager < Verse::Event::Manager::Base
        # Implementation
      end
    end

    class Plugin < Verse::Plugin::Base
      def on_init
        # Register the event manager
        Verse::Event::Manager.add_event_manager_type(:redis, Verse::Redis::Stream::EventManager)
      end
    end
  end
end
```

### Repository Plugins

Repository plugins provide implementations of the repository interface:

```ruby
module Verse
  module Sequel
    class Repository < Verse::Model::Repository::Base
      # Implementation
    end

    class Plugin < Verse::Plugin::Base
      def on_init
        # No registration needed, just use the repository in your application
      end
    end
  end
end
```

### HTTP Plugins

HTTP plugins provide HTTP server integration:

```ruby
module Verse
  module Http
    class Plugin < Verse::Plugin::Base
      def on_start(mode)
        return unless mode == :server

        # Start HTTP server
        @server = Server.new(config)
        @server.start
      end

      def on_stop
        # Stop HTTP server
        @server&.stop
      end
    end
  end
end
```

## Best Practices

### Plugin Design

- Keep plugins focused on a specific functionality
- Use meaningful names that reflect the functionality
- Follow the Verse naming conventions

### Dependency Management

- Declare dependencies explicitly
- Use dependency mapping for flexibility
- Handle missing dependencies gracefully

### Configuration

- Provide sensible defaults
- Validate configuration early
- Document configuration options

### Testing

- Test plugins in isolation
- Test integration with other plugins
- Test error cases and edge conditions

## Example: Complete Plugin

```ruby
module Verse
  module Redis
    class Plugin < Verse::Plugin::Base
      def dependencies
        [:logger]
      end

      def on_init
        # Initialize Redis connection
        @client = ::Redis.new(config)

        # Register event manager
        Verse::Event::Manager.add_event_manager_type(:redis, Verse::Redis::Stream::EventManager)

        # Log initialization
        logger.info "Redis plugin initialized"
      end

      def on_start(mode)
        # Start the plugin
        logger.info "Redis plugin started in #{mode} mode"
      end

      def on_stop
        # Stop the plugin
        @client.close
        logger.info "Redis plugin stopped"
      end

      def on_finalize
        # Clean up resources
        logger.info "Redis plugin finalized"
      end

      def client
        @client
      end
    end
  end
end
