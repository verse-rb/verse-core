# Error Handling

Error handling is a crucial aspect of building robust applications with the Verse framework. This document explains how error handling works in Verse Core and how to use it effectively.

## Overview

Verse Core provides a structured approach to error handling with:

- A hierarchy of error classes for different types of errors
- Consistent error propagation through the layers
- Error handling mechanisms at different levels
- Integration with the exposition layer for proper error responses

## Error Classes

Verse Core defines a hierarchy of error classes in the `Verse::Error` namespace:

| Error Class | Description | HTTP Status Code |
|-------------|-------------|------------------|
| `Verse::Error::Base` | Base class for all Verse errors | 500 |
| `Verse::Error::Unauthorized` | Authentication or authorization failure | 401 |
| `Verse::Error::BadRequest` | Invalid request parameters | 400 |
| `Verse::Error::NotFound` | Resource not found | 404 |
| `Verse::Error::RecordNotFound` | Database record not found | 404 |
| `Verse::Error::ValidationFailed` | Validation errors | 422 |
| `Verse::Error::CannotCreateRecord` | Failed to create a record | 422 |

### Base Error Class

All Verse errors inherit from `Verse::Error::Base`, which provides common functionality:

```ruby
module Verse
  module Error
    class Base < StandardError
      attr_reader :details

      def initialize(message = nil, details = nil)
        @details = details
        super(message)
      end
    end
  end
end
```

### Custom Error Classes

You can define custom error classes for your application:

```ruby
module Verse
  module Error
    class PaymentFailed < Base
      def initialize(message = "Payment processing failed", details = nil)
        super
      end
    end
  end
end
```

## Error Propagation

Errors are propagated through the layers of the application:

1. **Repository Layer**: Raises specific errors like `RecordNotFound`
2. **Service Layer**: Catches repository errors and raises domain-specific errors
3. **Exposition Layer**: Catches service errors and converts them to appropriate responses

### Repository Layer Errors

Repositories raise errors for database operations:

```ruby
class UserRepository < Verse::Model::Repository::Base
  def find!(id, scope: scoped(:read))
    user = find(id, scope:)
    raise Verse::Error::RecordNotFound, "User not found: #{id}" unless user
    user
  end
end
```

### Service Layer Errors

Services catch repository errors and raise domain-specific errors:

```ruby
class UserService < Verse::Service::Base
  use_repo users: UserRepository

  def get_user(id)
    users.find!(id)
  rescue Verse::Error::RecordNotFound
    raise Verse::Error::NotFound, "User not found: #{id}"
  end

  def create_user(attributes)
    validate_user_attributes(attributes)
    users.create(attributes)
  rescue Verse::Error::ValidationFailed => e
    raise Verse::Error::BadRequest, "Invalid user attributes: #{e.message}", e.details
  end

  private

  def validate_user_attributes(attributes)
    errors = {}
    errors[:name] = "can't be blank" if attributes[:name].to_s.empty?
    errors[:email] = "can't be blank" if attributes[:email].to_s.empty?

    raise Verse::Error::ValidationFailed.new("Validation failed", errors) if errors.any?
  end
end
```

### Exposition Layer Errors

The exposition layer catches service errors and converts them to appropriate responses:

```ruby
class UserExposition < Verse::Exposition::Base
  use_service user_service: UserService

  expose http_hook(:get, "/users/:id")
  def get_user(id)
    user_service.get_user(id)
  rescue Verse::Error::NotFound => e
    # The exposition layer will automatically convert this to a 404 response
    raise
  end

  expose http_hook(:post, "/users")
  def create_user(user_params)
    user_service.create_user(user_params)
  rescue Verse::Error::BadRequest => e
    # The exposition layer will automatically convert this to a 400 response
    raise
  end
end
```

## Error Handling in Handlers

The exposition layer uses handlers to process requests and handle errors. You can define custom error handling by creating a custom handler:

```ruby
class ErrorHandlerMiddleware < Verse::Exposition::Handler
  def call
    next_handler.call
  rescue Verse::Error::Base => e
    # Handle Verse errors
    handle_verse_error(e)
  rescue StandardError => e
    # Handle unexpected errors
    handle_unexpected_error(e)
  end

  private

  def handle_verse_error(error)
    case error
    when Verse::Error::Unauthorized
      { status: 401, body: { error: error.message } }
    when Verse::Error::BadRequest
      { status: 400, body: { error: error.message, details: error.details } }
    when Verse::Error::NotFound
      { status: 404, body: { error: error.message } }
    when Verse::Error::ValidationFailed
      { status: 422, body: { error: error.message, details: error.details } }
    else
      { status: 500, body: { error: error.message } }
    end
  end

  def handle_unexpected_error(error)
    # Log the error
    Verse.logger.error(error)

    # Return a generic error response
    { status: 500, body: { error: "An unexpected error occurred" } }
  end
end
```

## Error Handling in Services

Services should handle errors at the appropriate level:

```ruby
class PaymentService < Verse::Service::Base
  def process_payment(user_id, amount)
    user = user_repository.find!(user_id)

    begin
      payment_gateway.charge(user.payment_token, amount)
    rescue PaymentGateway::CardDeclined => e
      raise Verse::Error::PaymentFailed.new("Card declined", { reason: e.message })
    rescue PaymentGateway::InvalidCard => e
      raise Verse::Error::BadRequest.new("Invalid card", { reason: e.message })
    rescue PaymentGateway::Error => e
      # Log the error
      Verse.logger.error(e)

      # Raise a generic payment error
      raise Verse::Error::PaymentFailed.new("Payment processing failed", { reason: "gateway_error" })
    end
  end
end
```

## Error Handling in Repositories

Repositories should raise specific errors for database operations:

```ruby
class UserRepository < Verse::Model::Repository::Base
  def find!(id, scope: scoped(:read))
    user = find(id, scope:)
    raise Verse::Error::RecordNotFound, "User not found: #{id}" unless user
    user
  end

  def create!(attributes)
    user = create(attributes)
    raise Verse::Error::CannotCreateRecord, "Failed to create user" unless user
    user
  end

  def update!(id, attributes, scope: scoped(:update))
    user = update(id, attributes, scope:)
    raise Verse::Error::RecordNotFound, "User not found: #{id}" unless user
    user
  end

  def delete!(id, scope: scoped(:delete))
    result = delete(id, scope:)
    raise Verse::Error::RecordNotFound, "User not found: #{id}" unless result
    result
  end
end
```

## Validation Errors

Validation errors are a common type of error in web applications. Verse Core provides a `ValidationFailed` error class for handling validation errors:

```ruby
class UserService < Verse::Service::Base
  def create_user(attributes)
    errors = validate_user(attributes)

    if errors.any?
      raise Verse::Error::ValidationFailed.new("Validation failed", errors)
    end

    users.create(attributes)
  end

  private

  def validate_user(attributes)
    errors = {}

    # Validate name
    if attributes[:name].to_s.empty?
      errors[:name] = ["can't be blank"]
    elsif attributes[:name].to_s.length < 3
      errors[:name] = ["is too short (minimum is 3 characters)"]
    end

    # Validate email
    if attributes[:email].to_s.empty?
      errors[:email] = ["can't be blank"]
    elsif !attributes[:email].to_s.match?(/\A[^@\s]+@[^@\s]+\z/)
      errors[:email] = ["is not a valid email address"]
    end

    errors
  end
end
```

## Error Logging

Errors should be logged at the appropriate level:

```ruby
begin
  # Some operation that might fail
rescue Verse::Error::Base => e
  # Log Verse errors at the info level
  Verse.logger.info(e)
  raise
rescue StandardError => e
  # Log unexpected errors at the error level
  Verse.logger.error(e)
  raise Verse::Error::Base.new("An unexpected error occurred", { original_error: e.message })
end
```

## Best Practices

### Error Class Design

- Create specific error classes for different types of errors
- Use meaningful error messages that help diagnose the issue
- Include relevant details in the error object

### Error Propagation

- Raise errors at the appropriate level
- Catch and transform errors when crossing layer boundaries
- Let unexpected errors propagate to the top level for logging and handling

### Error Handling

- Handle errors at the appropriate level
- Log errors with sufficient context
- Provide meaningful error responses to clients

### Validation

- Validate input at the service layer
- Use the `ValidationFailed` error class for validation errors
- Include detailed validation errors in the error object

## Example: Complete Error Handling

```ruby
# Repository Layer
class UserRepository < Verse::Model::Repository::Base
  def find!(id, scope: scoped(:read))
    user = find(id, scope:)
    raise Verse::Error::RecordNotFound, "User not found: #{id}" unless user
    user
  end
end

# Service Layer
class UserService < Verse::Service::Base
  use_repo users: UserRepository

  def get_user(id)
    users.find!(id)
  rescue Verse::Error::RecordNotFound
    raise Verse::Error::NotFound, "User not found: #{id}"
  end

  def create_user(attributes)
    errors = validate_user(attributes)

    if errors.any?
      raise Verse::Error::ValidationFailed.new("Validation failed", errors)
    end

    users.create(attributes)
  rescue Verse::Error::CannotCreateRecord => e
    raise Verse::Error::BadRequest, "Failed to create user: #{e.message}"
  end

  private

  def validate_user(attributes)
    errors = {}

    # Validate name
    if attributes[:name].to_s.empty?
      errors[:name] = ["can't be blank"]
    end

    # Validate email
    if attributes[:email].to_s.empty?
      errors[:email] = ["can't be blank"]
    elsif !attributes[:email].to_s.match?(/\A[^@\s]+@[^@\s]+\z/)
      errors[:email] = ["is not a valid email address"]
    end

    errors
  end
end

# Exposition Layer
class UserExposition < Verse::Exposition::Base
  use_service user_service: UserService

  expose http_hook(:get, "/users/:id")
  def get_user(id)
    user_service.get_user(id)
  rescue Verse::Error::NotFound => e
    # The exposition layer will automatically convert this to a 404 response
    raise
  end

  expose http_hook(:post, "/users")
  def create_user(user_params)
    user_service.create_user(user_params)
  rescue Verse::Error::ValidationFailed, Verse::Error::BadRequest => e
    # The exposition layer will automatically convert these to appropriate responses
    raise
  end
end
