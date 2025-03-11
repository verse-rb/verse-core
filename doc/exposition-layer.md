# Exposition Layer

The exposition layer is a core component of the Verse framework, responsible for exposing services to the outside world. This document explains how the exposition layer works and how to use it.

## Overview

The exposition layer in Verse Core serves as the interface between external clients and the internal services. It is responsible for:

- Handling incoming requests
- Authentication and authorization
- Request validation
- Routing to appropriate services
- Response formatting
- Error handling

## Exposition Base Class

All expositions in Verse Core inherit from `Verse::Exposition::Base`, which provides common functionality:

```ruby
class MyExposition < Verse::Exposition::Base
  # Exposition implementation
end
```

## Exposing Endpoints

Endpoints are exposed using the `expose` method, which takes a hook and optionally a block for configuration:

| Hook Type | Description | Example |
|-----------|-------------|---------|
| HTTP | Exposes an HTTP endpoint (need verse-http) | `expose on_http(:get, "/users")` |
| Resource Event | Exposes an event handler | `expose on_resource_event("users", "created")` |
| Event | Exposes an event handler | `expose on_event("custom_channel")` |
| Command | Exposes a command handler | `expose on_command("users:get")` |
| CRON | Exposes on schedule (need verse-redis) | `expose on_schedule("1 * * * *")` |

Example:

```ruby
class UserExposition < Verse::Exposition::Base
  # Expose an HTTP endpoint
  expose http_hook(:get, "/users/:id") do
    # Endpoint configuration
  end

  # Method that will be called when the endpoint is hit
  def get_user(id)
    user_service.get_user(id)
  end
end
```

## Handler Chain

The exposition layer uses a handler chain pattern to process requests. Handlers are middleware components that can:

- Authenticate requests
- Validate input
- Transform responses
- Handle errors
- Log requests

Handlers are executed in order, with each handler calling the next one in the chain.

### Built-in Handlers

Verse Core includes several built-in handlers:

| Handler | Description |
|---------|-------------|
| `Verse::Auth::CheckAuthenticationHandler` | Ensures the request is authenticated |
| `Verse::Exposition::Handler` | Base handler that executes the endpoint method |

### Adding Handlers

Handlers can be added to an exposition using the `prepend_handler` and `append_handler` methods:

```ruby
class UserExposition < Verse::Exposition::Base
  # Add a handler to the beginning of the chain
  prepend_handler MyAuthHandler

  # Add a handler to the end of the chain
  append_handler MyLoggingHandler

  # ...
end
```

### Custom Handlers

Custom handlers can be created by inheriting from `Verse::Exposition::Handler`:

```ruby
class MyCustomHandler < Verse::Exposition::Handler
  def call
    # Do something before the next handler
    result = next_handler.call
    # Do something after the next handler
    result
  end
end
```

## Service Integration

Expositions can easily integrate with services using the `use_service` method:

```ruby
class UserExposition < Verse::Exposition::Base
  # Define services to use
  use_service user_service: UserService,
              post_service: PostService

  expose http_hook(:get, "/users/:id")
  def get_user(id)
    # Use the service
    user_service.get_user(id)
  end
end
```

The `use_service` method:

- Creates accessor methods for the services
- Passes the authentication context to the services
- Manages service lifecycle

## Authentication Context

Expositions receive an authentication context when initialized, which represents the current user or system context:

```ruby
def initialize(auth_context, action, hook, **fields)
  @auth_context   = auth_context
  @current_action = action
  @hook           = hook
  # ...
end
```

The authentication context is passed to services and used for authorization checks.

## Hook Types

Verse Core supports different types of hooks for exposing endpoints:

### HTTP Hooks

HTTP hooks expose endpoints over HTTP:

```ruby
expose http_hook(:get, "/users/:id")
def get_user(id)
  # Handle GET /users/:id
end

expose http_hook(:post, "/users")
def create_user(user_params)
  # Handle POST /users
end
```

### Event Hooks

Event hooks handle events from the event system:

```ruby
expose on_resource_event("users", "created")
def handle_user_created(message, channel)
  # Handle users:created event
end
```

### Command Hooks

Command hooks handle command requests:

```ruby
expose on_command("users:get")
def get_user(message, channel)
  # Handle users:get command
  message.reply(user_service.get_user(message.content[:id]))
end
```

## Registration

Expositions need to be registered to be active:

```ruby
# In an initializer
UserExposition.register
```

The `register` method registers all exposed endpoints with their respective hooks.

## Metadata and Documentation

Expositions can include metadata and documentation:

```ruby
class UserExposition < Verse::Exposition::Base
  # Set description for the exposition
  desc "User management API"

  # Set metadata for the exposition
  meta version: "1.0"

  # ...
end
```

This metadata can be used for generating documentation or API specifications.

## Error Handling

Errors in the exposition layer are handled by the handler chain. By default, errors are converted to appropriate responses based on the error type:

| Error Type | Response |
|------------|----------|
| `Verse::Error::Unauthorized` | 401 Unauthorized |
| `Verse::Error::BadRequest` | 400 Bad Request |
| `Verse::Error::NotFound` | 404 Not Found |
| `Verse::Error::ValidationFailed` | 422 Unprocessable Entity |
| Other errors | 500 Internal Server Error |

Custom error handling can be implemented using custom handlers.

## Best Practices

### Exposition Organization

- Keep expositions focused on a specific domain or entity
- Use meaningful names that reflect the domain
- Group related endpoints in the same exposition

### Endpoint Design

- Use clear, descriptive method names
- Keep methods focused on delegating to services
- Return meaningful values or raise appropriate exceptions

### Handler Design

- Keep handlers focused on a single responsibility
- Use the handler chain for cross-cutting concerns
- Consider the order of handlers

## Example: Complete Exposition

```ruby
class UserExposition < Verse::Exposition::Base
  desc "User management API"

  # Add authentication handler
  prepend_handler Verse::Auth::CheckAuthenticationHandler

  # Define services to use
  use_service user_service: UserService

  # Expose HTTP endpoints
  expose http_hook(:get, "/users")
  def get_users
    user_service.get_users
  end

  expose http_hook(:get, "/users/:id")
  def get_user(id)
    user_service.get_user(id)
  end

  expose http_hook(:post, "/users")
  def create_user(user_params)
    user_service.create_user(user_params)
  end

  expose http_hook(:put, "/users/:id")
  def update_user(id, user_params)
    user_service.update_user(id, user_params)
  end

  expose http_hook(:delete, "/users/:id")
  def delete_user(id)
    user_service.delete_user(id)
  end

  # Expose event handler
  expose on_resource_event("users", "created")
  def handle_user_created(message, channel)
    # Handle user created event
    logger.info "User created: #{message.content[:id]}"
  end
end
