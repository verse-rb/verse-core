# Utilities

Verse Core provides a set of utility functions and classes to help with common tasks. This document explains the available utilities and how to use them.

## Overview

The utilities in Verse Core are organized in the `Verse::Util` namespace and include:

- Array with metadata
- Assertion utilities
- Autovalidated endpoint
- Extension methods
- Future
- Hash utilities
- Inflector
- Dependency injection
- Iterator
- Reflection
- String utilities

## Array with Metadata

`Verse::Util::ArrayWithMetadata` is a class that extends `Array` to include metadata:

```ruby
# Create an array with metadata
users = Verse::Util::ArrayWithMetadata.new(
  [user1, user2, user3],
  metadata: { total_count: 100, page: 1 }
)

# Access the array elements
users.each do |user|
  puts user.name
end

# Access the metadata
puts "Total count: #{users.metadata[:total_count]}"
puts "Page: #{users.metadata[:page]}"
```

This is particularly useful for paginated results, where you need to return both the items and pagination information.

## Assertion

`Verse::Util::Assertion` provides methods for asserting conditions:

```ruby
include Verse::Util::Assertion
# Assert a condition
assert(user.admin?) do
  "User must be an admin"
end

# Assert a value is not nil
assert(!user.nil?, "User cannot be nil")

# Assert with custom error class:
assert(user.admin?, "User must be an admin", MyCustomError)
```

If the assertion fails, it raises an `RuntimeError` with the provided message.

## Autovalidated Endpoint

`Verse::Util::AutovalidatedEndpoint` is a module that provides validation for exposition endpoints:

```ruby
class UserExposition < Verse::Exposition::Base
  expose on_http(:post, "/users") do
    input do
      # Define input schema
      field :name, String
      field(:email, String).rule("must be an email") do |age|
        age =~ /\A[^@\s]+@[^@\s]+\z/
      end
      field?(:age, Integer).rule("must be at least 18") { |age| age >= 18 }
    end
    param :name, type: String, required: true
    param :email, type: String, required: true, format: /\A[^@\s]+@[^@\s]+\z/
    param :age, type: Integer, required: false, min: 18
  end
  def create_user(params)
    # params are validated based on the param definitions
    user_service.create_user(params)
  end
end
```

Check verse-schema for more information on defining input schemas.

The `param` method defines the expected parameters and their validation rules. If the validation fails, a `Verse::Error::ValidationFailed` is raised with the validation errors.

## Future

`Verse::Util::Future` provides a way to work with asynchronous operations:

```ruby
# Create a future
future = Verse::Util::Future.new do
  # Long-running operation
  sleep 1
  "Result"
end

# Check if the future is ready
future.ready? # => false

# Wait for the future to complete
future.wait # => "Result"

# Now the future is ready
future.ready? # => true
future.value # => "Result"
```

Futures are useful for performing operations in parallel.

## Hash Util

`Verse::Util::HashUtil` provides utility methods for working with hashes:

```ruby
# Deep symbolize keys
hash = { "a" => { "b" => 2 } }
Verse::Util::HashUtil.deep_symbolize_keys(hash) # => { a: { b: 2 } }
```

## Inflector

`Verse::Util::Inflector` provides methods for inflecting strings:

```ruby
# Pluralize
Verse.inflector.pluralize("user") # => "users"
Verse.inflector.pluralize("person") # => "people"

# Singularize
Verse.inflector.singularize("users") # => "user"
Verse.inflector.singularize("people") # => "person"

# Past tense
Verse.inflector.inflect_past("create user") # => "user created"
```

The inflector is used internally by Verse Core for various naming conventions.

## Inject

`Verse::Util::Inject` provides dependency injection capabilities:

```ruby
class UserService < Verse::Service::Base
  extend Verse::Util::Inject

  # Inject dependencies
  inject :email_sender, EmailSender
  inject :payment_gateway, PaymentGateway

  def send_welcome_email(user)
    email_sender.send_email(user.email, "Welcome!")
  end

  def process_payment(user, amount)
    payment_gateway.charge(user.payment_token, amount)
  end
end
```

The `inject` method creates accessor methods for the dependencies, which are lazily initialized when first accessed.

## Iterator

`Verse::Util::Iterator` provides methods for working with iterators:

```ruby
# Create a chunked iterator
iterator = Verse::Util::Iterator.chunk_iterator(1) do |page|
  # Fetch data for the current page
  data = fetch_data(page: page, per_page: 10)

  # Return nil when there's no more data
  data.empty? ? nil : data
end

# Iterate over all chunks
iterator.each do |chunk|
  process_chunk(chunk)
end

# Convert to an array
all_data = iterator.to_a
```

The chunked iterator is useful for paginated data, where you want to iterate over all pages without loading everything into memory at once.

## Reflection

`Verse::Util::Reflection` provides methods for working with Ruby's reflection capabilities:

```ruby
# Get a constant from a string
klass = Verse::Util::Reflection.constantize("UserService")
```

## String Util

`Verse::Util::StringUtil` provides utility methods for working with strings:

```ruby
# Camelize
Verse::Util::StringUtil.camelize("user_service") # => "UserService"

# Underscore
Verse::Util::StringUtil.underscore("UserService") # => "user_service"

# Titleize
Verse::Util::StringUtil.titleize("user_service") # => "User Service"

# Strip indent
Verse::Util::StringUtil.strip_indent("  Hello\n  World") # => "Hello\nWorld"
```

## Best Practices

### Using Array with Metadata

- Use `ArrayWithMetadata` for paginated results
- Include relevant metadata like total count and page number
- Access metadata using the `metadata` method

### Using Assertion

- Use assertions to validate preconditions
- Provide meaningful error messages
- Use assertions for internal validation, not for user input validation

### Using Autovalidated Endpoint

- Define parameters for each endpoint
- Use appropriate types and validation rules
- Handle validation errors appropriately

### Using Extension Methods

- Use extension methods to simplify common operations
- Be aware of potential conflicts with other libraries
- Consider creating your own extensions for project-specific needs

### Using Future

- Use futures for operations that can be performed in parallel
- Be careful with shared state in futures
- Handle exceptions in futures appropriately

### Using Hash Util

- Use hash utilities for common hash operations
- Consider performance implications for large hashes
- Use deep operations only when necessary

### Using Inflector

- Use the inflector for consistent naming conventions
- Be aware of irregular pluralizations
- Consider adding custom inflections for domain-specific terms

### Using Inject

- Use dependency injection for testability
- Inject dependencies at the class level
- Use meaningful names for injected dependencies

### Using Iterator

- Use iterators for large datasets
- Use chunked iterators for paginated data
- Handle empty results appropriately

### Using Reflection

- Use reflection sparingly
- Handle missing constants gracefully
- Consider performance implications

### Using String Util

- Use string utilities for consistent string transformations
- Be aware of potential conflicts with other libraries
- Consider creating your own utilities for project-specific needs
