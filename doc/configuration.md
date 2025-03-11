# Configuration

Configuration is a core aspect of the Verse framework, allowing you to customize the behavior of your application. This document explains how the configuration system works and how to use it.

## Overview

The configuration system in Verse Core provides a way to:

- Configure the service name and environment
- Set up plugins and their dependencies
- Configure the event manager
- Set application-specific settings

## Configuration Structure

The configuration is a nested hash structure that can be accessed through the `Verse::Config` module:

```ruby
Verse::Config.config = {
  service_name: "my-service",
  environment: "development",
  plugins: [
    {
      name: "redis",
      plugin: "redis",
      config: {
        url: "redis://localhost:6379/0"
      }
    }
  ],
  em: {
    adapter: :redis,
    config: {
      url: "redis://localhost:6379/0"
    }
  },
  logging: {
    level: :info
  },
  # Application-specific settings
  app: {
    feature_flags: {
      new_ui: true
    }
  }
}
```

## Configuration Loading

The configuration is typically loaded from YAML files in the `config` directory:

```ruby
# In verse-core/lib/verse/init.rb
Verse::Config.init(config_path)
```

The `init` method loads configuration files based on the current environment:

1. `config/default.yml` - Default configuration for all environments
2. `config/#{environment}.yml` - Environment-specific configuration (e.g., `development.yml`, `production.yml`)
3. `config/local.yml` - Local overrides (not committed to version control)

## Core Configuration Options

### Service Name

The service name is used to identify the service in logs, events, and other contexts:

```ruby
# In configuration
service_name: "my-service"

# In code
Verse.service_name # => "my-service"
```

### Environment

The environment determines which configuration files are loaded and can be used to conditionally enable features:

```ruby
# Set by environment variable
ENV["APP_ENVIRONMENT"] = "development"

# In code
Verse.environment # => :development
```

### Logging

Logging configuration controls the log level and other logging settings:

```ruby
# In configuration
logging:
  level: :info

# In code
Verse.logger.level # => Logger::INFO
```

## Plugin Configuration

Plugins are configured through the `plugins` array in the configuration:

```ruby
# In configuration
plugins:
  - name: "redis"
    plugin: "redis"
    config:
      url: "redis://localhost:6379/0"
  - name: "sequel"
    plugin: "sequel"
    config:
      url: "postgres://localhost/myapp"
    mapping:
      db: "sequel" # Map `db` dependency to sequel plugin
```

Each plugin configuration includes:

- `name`: The name of the plugin instance
- `plugin`: The name of the plugin class (or a Ruby class)
- `config`: Plugin-specific configuration
- `mapping`: Dependency mapping for the plugin

## Event Manager Configuration

The event manager is configured through the `em` key in the configuration:

```ruby
# In configuration
em:
  adapter: :redis
  config:
    url: "redis://localhost:6379/0"

# In code
Verse.event_manager # => Instance of Verse::Redis::Stream::EventManager
```

The `adapter` specifies which event manager implementation to use, and the `config` provides adapter-specific configuration.

## Application-Specific Configuration

You can add application-specific configuration under any key in the configuration:

```ruby
# In configuration
app:
  feature_flags:
    new_ui: true
  api:
    url: "https://api.example.com"
    timeout: 30

# In code
Verse::Config.config.dig(:app, :feature_flags, :new_ui) # => true
Verse::Config.config.dig(:app, :api, :url) # => "https://api.example.com"
```

## Accessing Configuration

The configuration can be accessed through the `Verse::Config` module:

```ruby
# Get the entire configuration
config = Verse::Config.config

# Get a specific value
service_name = Verse::Config.config[:service_name]

# Get a nested value
api_url = Verse::Config.config.dig(:app, :api, :url)
```

## Environment Variables

Environment variables can be used to override configuration values:

```ruby
# Set environment variables
ENV["APP_ENVIRONMENT"] = "production"
ENV["REDIS_URL"] = "redis://redis.example.com:6379/0"

# In configuration
em:
  adapter: :redis
  config:
    url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/0") %>
```

## Configuration Schema

Verse Core provides a schema validation system for configuration through the `Verse::Config::Schema` module:

```ruby
# Define a schema
Verse::Config::Schema.define do
  required(:service_name).filled(:string)
  required(:environment).filled(:string)

  optional(:plugins).array(:hash) do
    required(:name).filled(:string)
    required(:plugin).filled(:string)
    optional(:config).hash
    optional(:mapping).hash
  end

  optional(:em).hash do
    required(:adapter).filled(:symbol)
    optional(:config).hash
  end

  optional(:logging).hash do
    optional(:level).filled(:symbol)
  end

  optional(:app).hash
end

# Validate configuration
Verse::Config::Schema.validate(Verse::Config.config)
```

## Best Practices

### Configuration Organization

- Group related settings under meaningful keys
- Use nested structures for complex configuration
- Keep sensitive information in environment variables

### Environment-Specific Configuration

- Use `default.yml` for common settings
- Use environment-specific files for environment-specific settings
- Use `local.yml` for local development overrides

### Plugin Configuration

- Follow plugin documentation for required configuration
- Use meaningful names for plugin instances
- Use dependency mapping for flexibility

### Sensitive Information

- Never commit sensitive information to version control
- Use environment variables for sensitive information
- Consider using a secrets management system for production

## Example: Complete Configuration

```yaml
# config/default.yml
service_name: "my-service"
environment: <%= ENV.fetch("APP_ENVIRONMENT", "development") %>

plugins:
  - name: "redis"
    plugin: "redis"
    config:
      url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/0") %>

  - name: "sequel"
    plugin: "sequel"
    config:
      url: <%= ENV.fetch("DATABASE_URL", "postgres://localhost/myapp") %>

  - name: "http"
    plugin: "http"
    config:
      port: 3000
      host: "0.0.0.0"

em:
  adapter: :redis
  config:
    url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/0") %>

logging:
  level: :info

app:
  feature_flags:
    new_ui: true
  api:
    url: "https://api.example.com"
    timeout: 30

# config/development.yml
logging:
  level: :debug

app:
  feature_flags:
    new_ui: true

# config/production.yml
logging:
  level: :warn

app:
  feature_flags:
    new_ui: false
