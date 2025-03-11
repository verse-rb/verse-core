# Service Layer

The service layer is a core component of the Verse framework, containing the business logic of the application. This document explains how the service layer works and how to use it.

## Overview

Services in Verse Core are responsible for:

- Implementing business logic
- Orchestrating operations across multiple repositories
- Publishing events
- Enforcing business rules and validations

The service layer sits between the exposition layer (which handles external requests) and the model layer (which handles data persistence).

## Service Base Class

All services in Verse Core inherit from `Verse::Service::Base`, which provides common functionality:

```ruby
class MyService < Verse::Service::Base
  # Service implementation
end
```

The base service class provides:

- Authentication context handling
- Metadata management
- Repository integration
- Dependency injection

## Authentication Context

Services receive an authentication context when initialized, which represents the current user or system context:

```ruby
def initialize(auth_context, metadata = {})
  @auth_context = auth_context
  @metadata     = metadata
end
```

The authentication context is used to enforce access control, filter data based on user permissions, and track who performed operations.

## Metadata

Services can receive and manage metadata, which is useful for tracking request information, passing context between services, and logging and debugging.

The `with_metadata` method allows temporarily extending the metadata for a specific operation:

```ruby
def some_operation
  with_metadata(operation: "create_user") do
    # Metadata will include { operation: "create_user" }
    # ...
  end
  # Original metadata is restored
end
```

## Repository Integration

Services can easily integrate with repositories using the `use_repo` method:

```ruby
class UserService < Verse::Service::Base
  use_repo users: UserRepository,
          posts: PostRepository

  def create_user(attributes)
    users.create(attributes)
  end

  def get_user_posts(user_id)
    posts.index({ user_id: user_id })
  end
end
```

The `use_repo` method:

- Creates accessor methods for the repositories
- Passes the authentication context to the repositories
- Propagates metadata to the repositories

For system-level operations that bypass normal authorization, you can use `use_system_repo`:

```ruby
class AdminService < Verse::Service::Base
  use_system_repo users: UserRepository

  def delete_all_users
    users.delete_all
  end
end
```

## Dependency Injection

Services can inject dependencies using the `inject` method:

```ruby
class NotificationService < Verse::Service::Base
  inject EmailSender, from: "noreply@example.tld"

  def notify_user(user_id, message)
    user = users.find(user_id)
    email_sender.send_email(user.email, message)
  end
end
```

## Best Practices

### Service Organization

- Keep services focused on a specific domain or entity
- Use meaningful names that reflect the domain
- Group related operations in the same service

### Method Design

- Use clear, descriptive method names
- Keep methods focused on a single responsibility
- Return meaningful values or raise appropriate exceptions

### Error Handling

- Use domain-specific exceptions
- Handle expected errors gracefully
- Let unexpected errors propagate for global handling

### Testing

- Test services in isolation using mocks for dependencies
- Test the integration with repositories using in-memory repositories
- Test error cases and edge conditions

## Example Service

```ruby
class UserService < Verse::Service::Base
  use users: UserRepository,
      posts: PostRepository

  def create_user(attributes)
    # Validate attributes
    validate_attributes(attributes)

    # Create the user
    user = users.create(attributes)

    # Publish an event
    Verse.event_manager.publish_resource_event(
      resource_type: "users",
      resource_id: user.id,
      event: "created",
      payload: user.to_h
    )

    user
  end

  def update_user(id, attributes)
    # Find the user
    user = users.find(id)

    # Update the user
    updated_user = users.update(id, attributes)

    # Publish an event
    Verse.event_manager.publish_resource_event(
      resource_type: "users",
      resource_id: id,
      event: "updated",
      payload: updated_user.to_h
    )

    updated_user
  end

  def delete_user(id)
    # Delete the user
    users.delete(id)

    # Publish an event
    Verse.event_manager.publish_resource_event(
      resource_type: "users",
      resource_id: id,
      event: "deleted",
      payload: { id: id }
    )
  end

  private

  def validate_attributes(attributes)
    # Implement validation logic
  end
end
