# Model Layer

The model layer is a core component of the Verse framework, handling data persistence and retrieval. This document explains how the model layer works and how to use it.

## Overview

The model layer in Verse Core consists of two main components:

1. **Records**: Immutable data objects that represent domain entities
2. **Repositories**: Data access objects that provide CRUD operations and query capabilities

This separation follows the Repository pattern, which decouples the domain model from the data access logic.

## Records

Records in Verse Core are immutable data objects that represent domain entities. They are defined using the `Verse::Model::Record::Base` class:

```ruby
class UserRecord < Verse::Model::Record::Base
  field :id, type: Integer, primary: true
  field :name, type: String
  field :email, type: String
  field :created_at, type: Time, readonly: true

  # Relationships
  has_many :posts
  has_one :profile
  belongs_to :organization
end
```

### Field Definition

Fields are defined using the `field` method, which accepts the following options:

- `type`: The type of the field (e.g., String, Integer, Time)
- `primary`: Whether the field is the primary key
- `visible`: Whether the field should be included in serialization.
- `readonly`: Whether the field can be modified. This is a flag which can be used by tools at the exposition layer to prevent modification of certain fields. Please note that Record are always immutable.
- `meta`: Additional metadata for the field. Useful for documentation or validation purposes

You can also define computed fields by providing a block:

```ruby
field :full_name do
  "#{first_name} #{last_name}"
end
```

### Relationships

Records can define relationships with other records:

- `has_many`: One-to-many relationship
- `has_one`: One-to-one relationship
- `belongs_to`: Many-to-one relationship

These relationships are used to fetch related data efficiently:

```ruby
# Define relationships
class UserRecord < Verse::Model::Record::Base
  field :id, type: Integer, primary: true
  field :name, type: String

  has_many :posts
end

class PostRecord < Verse::Model::Record::Base
  field :id, type: Integer, primary: true
  field :title, type: String
  field :user_id, type: Integer

  belongs_to :user
end

# Use relationships
user = user_repository.find(1, included: ["posts"])
posts = user.posts # Already loaded, no additional query
```

### Enums

Records can define enum fields for fields with a fixed set of values:

```ruby
class UserRecord < Verse::Model::Record::Base
  field :id, type: Integer, primary: true
  field :name, type: String
  field :status, type: String

  enum :status, [:active, :inactive, :suspended], prefix: "is"
end

# Usage
user = user_repository.find(1)
user.is_active?    # => true
user.is_inactive?  # => false
```

## Repositories

Repositories in Verse Core provide data access operations for records. They are defined using the `Verse::Model::Repository::Base` class or one of its implementations:

```ruby
class UserRepository < Verse::Model::Repository::Base
  # Repository implementation
end
```

Verse Core provides several repository implementations:

- `Verse::Model::Repository::Base`: Base class for all repositories
- `Verse::Model::InMemory::Repository`: In-memory repository for testing

Additional implementations are available through plugins:

- `Verse::Sequel::Repository`: SQL database repository (verse-sequel plugin)
- `Verse::Redis::Repository`: Redis repository (verse-redis plugin)

### CRUD Operations

Repositories provide standard CRUD operations:

```ruby
# Create
user = user_repository.create(name: "John", email: "john@example.com")

# Read
user = user_repository.find(1)
users = user_repository.index({ status: "active" })

# Update
updated_user = user_repository.update(1, { name: "John Doe" })

# Delete
user_repository.delete(1)
```

### Query Operations

Repositories provide query operations for filtering, pagination, and sorting:

```ruby
# Basic filtering
users = user_repository.index({ status: "active" })

# Advanced filtering with operators
users = user_repository.index({
  "name__contains" => "John",
  "created_at__gt" => 1.week.ago
})

# Pagination
users = user_repository.index({}, page: 2, items_per_page: 10)

# Sorting
users = user_repository.index({}, sort: { created_at: :desc })

# Including relationships
users = user_repository.index({}, included: ["posts", "profile"])
```

### Transactions

Repositories support transactions for atomic operations:

```ruby
user_repository.transaction do
  user = user_repository.create(name: "John")
  profile_repository.create(user_id: user.id, bio: "...")
end
```

### Event Dispatching

Repositories can dispatch events when records are created, updated, or deleted:

```ruby
# In the repository class
class UserRepository < Verse::Model::Repository::Base
  event
  def update(id, attributes, scope: scoped(:update))
    # Implementation
  end

  event(creation: true)
  def create(attributes)
    # Implementation
  end

  event
  def delete(id, scope: scoped(:delete))
    # Implementation
  end
end
```

The `event` decorator registers the method to dispatch events when called. The events are dispatched according to the event mode set in the `Verse::Event::Dispatcher`.

## In-Memory Repository

The `Verse::Model::InMemory::Repository` provides an in-memory implementation of the repository interface, which is useful for testing:

```ruby
class UserRepository < Verse::Model::InMemory::Repository
  # No additional implementation needed for basic functionality
end
```

The in-memory repository stores records in memory and provides all the standard repository operations.

## Best Practices

### Record Design

- Keep records focused on representing domain entities
- Use meaningful field names that reflect the domain
- Define relationships to represent domain associations
- Use computed fields for derived data

### Repository Design

- Keep repositories focused on data access operations
- Use meaningful method names for custom queries
- Handle errors gracefully and provide meaningful error messages
- Use transactions for operations that need to be atomic

### Testing

- Use in-memory repositories for testing
- Test CRUD operations and custom queries
- Test error cases and edge conditions
