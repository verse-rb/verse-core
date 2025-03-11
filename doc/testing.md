# Testing

Testing is a crucial aspect of developing applications with the Verse framework. This document explains how to test different components of a Verse application.

## Overview

Verse Core provides several tools and helpers for testing:

- Test helpers for services, repositories, and expositions
- In-memory repositories for testing without a database
- Event testing utilities
- Authentication context helpers

## RSpec Metadata Types

Verse provides special RSpec metadata types that simplify testing different components:

| Metadata Type | Description | Features |
|---------------|-------------|----------|
| `type: :exposition` | For testing exposition endpoints | HTTP testing with get/post, fake users, transaction rollback |
| `type: :service` | For testing service objects | Access to service object with current auth context |
| `type: :repository` | For testing repositories | Repository helpers, transaction rollback |

### Using `type: :exposition`

The `type: :exposition` metadata allows testing HTTP endpoints using get/post methods and fake users (requires verse-http). Tests run in a transaction and roll back at the end of the test.

```ruby
RSpec.describe UserExposition, type: :exposition do
  describe "GET /users", as: :user do
    it "returns users" do
      # Create test users
      create_user(name: "John")
      create_user(name: "Jane")

      # Make a GET request
      get "/users"

      # Verify response
      expect(last_response.status).to eq(200)
      expect(last_response.body[:data].count).to eq(2)
    end
  end

  describe "POST /users" do
    it "creates a user", as: :user do
      # Make a POST request
      post "/users", { name: "John", email: "john@example.com" }

      # Verify response
      expect(last_response.status).to eq(201)
      expect(last_response.body[:data][:name]).to eq("John")
    end
  end
end
```

### Using `type: :service`

The `type: :service` metadata allows testing service objects with the current authentication context. It provides a `service` helper method that returns an instance of the service with the current auth context.

Service do not rollback on their own, so you need to manage transactions manually if needed.
It is better to mock repository, using `allow(service).to receive(:users).and_return(double)`, or using in-memory repository during the test for example.

```ruby
RSpec.describe UserService, type: :service do
  describe "#create_user" do
    it "creates a user" do
      user = service.create_user(name: "John", email: "john@example.com")
      expect(user.name).to eq("John")
      expect(user.email).to eq("john@example.com")
    end
  end

  describe "#get_users" do
    it "returns users based on auth context" do
      # As system user (full access)
      users = service.get_users
      expect(users.count).to eq(User.count)

      # As regular user (limited access)
      as :user do
        users = service.get_users
        expect(users.count).to eq(1)
        expect(users.first.id).to eq(current_auth_context.metadata[:user_id])
      end
    end
  end
end
```

### Using `type: :repository`

The `type: :repository` metadata provides helpers for testing repositories. Tests run in a transaction and roll back at the end of the test.

```ruby
RSpec.describe UserRepository, type: :repository do
  describe "#create" do
    it "creates a user" do
      user = repository.create(name: "John", email: "john@example.com")
      expect(user.name).to eq("John")
      expect(user.email).to eq("john@example.com")
    end
  end

  describe "#find" do
    it "finds a user by id" do
      created_user = repository.create(name: "John", email: "john@example.com")
      found_user = repository.find(created_user.id)
      expect(found_user.id).to eq(created_user.id)
    end
  end
end
```

## Changing Auth Context

You can change the authentication context during tests using the `as` helper:

```ruby
RSpec.describe UserService, type: :service do
  describe "#get_users" do
    it "returns different results based on auth context" do
      # As system user
      puts current_auth_context # context of the system

      # As regular user
      as :user do
        puts current_auth_context # context of the user
      end

      # As admin
      as :admin do
        puts current_auth_context # context of the admin
      end
    end
  end
end
```

## Setting Up Test Users

You need to add test users in your spec helper:

```ruby
# In spec/spec_helper.rb
Verse::Spec.add_user(
  :user,           # Role name
  "user",          # Role in the backend
  user_data: {     # User data available in auth context metadata
    id: 1,
    person_id: 1,
    name: "Staff Account",
    email: "staff@example.com"
  }
)

Verse::Spec.add_user(
  :admin,
  "admin",
  user_data: {
    id: 2,
    person_id: 2,
    name: "Admin Account",
    email: "admin@example.com"
  }
)
```

These users can then be used in tests with the `as` helper.

## Testing Events

Verse provides matchers for testing events:

```ruby
require "verse/spec/matchers/receive_event"

RSpec.describe UserService, type: :service do
  include Verse::Spec::Matchers::ReceiveEvent

  describe "#create_user" do
    it "publishes a user created event" do
      expect {
        service.create_user(name: "John", email: "john@example.com")
      }.to publish_resource_event(
        resource_type: "users",
        event: "created"
      )
    end
  end
end
```

## Testing with In-Memory Repositories

In-memory repositories are useful for testing without a database:

```ruby
class InMemoryUserRepository < Verse::Model::InMemory::Repository
  # No additional implementation needed for basic functionality
end

RSpec.describe UserService do
  let(:auth_context) { Verse::Auth::Context[:system] }
  let(:repository) { InMemoryUserRepository.new(auth_context) }
  let(:service) { UserService.new(auth_context) }

  before do
    # Replace the real repository with the in-memory one
    allow(service).to receive(:users).and_return(repository)
  end

  describe "#get_users" do
    it "returns users" do
      repository.create(name: "John", email: "john@example.com")
      repository.create(name: "Jane", email: "jane@example.com")

      users = service.get_users
      expect(users.count).to eq(2)
    end
  end
end
```

## Testing with Event Dispatcher

When using :repository or :exposition metadata, code is run in a transaction block which will rollback. Since events are dispatched after the transaction is committed, you can't test event dispatching directly in these tests. In this case, you should use the `Verse::Event::Dispatcher` to control event dispatching.

The event dispatcher can be controlled in tests to ensure events are dispatched at the right time:

```ruby
RSpec.describe UserService, type: :service do
  before do
    # Set event mode to manual
    Verse::Event::Dispatcher.event_mode = :manual
  end

  after do
    # Reset event mode
    Verse::Event::Dispatcher.event_mode = :on_commit
  end

  describe "#create_user" do
    it "dispatches events after commit" do
      # Create a user
      service.create_user(name: "John", email: "john@example.com")

      # No events should be dispatched yet
      expect(DummyEventManager.channels["users:created"]).to be_nil

      # Manually dispatch events
      Verse::Event::Dispatcher.dispatch!

      # Now events should be dispatched
      expect(DummyEventManager.channels["users:created"]).not_to be_nil
    end
  end
end
```

## Integration Testing

Integration tests verify that different components work together correctly:

```ruby
RSpec.describe "User Management", type: :exposition do
  before do
    # Create test users
    create_user(name: "John", email: "john@example.com")
    create_user(name: "Jane", email: "jane@example.com")
  end

  it "lists users" do
    get "/users"
    expect(response.status).to eq(200)
    expect(response.body[:data].count).to eq(2)
  end

  it "creates a user" do
    post "/users", { name: "Alice", email: "alice@example.com" }
    expect(response.status).to eq(201)

    # Verify the user was created
    get "/users/#{response.body[:data][:id]}"
    expect(response.status).to eq(200)
    expect(response.body[:data][:name]).to eq("Alice")
  end
end
```

## Best Practices

### Test Organization

- Use the appropriate metadata type for each component
- Group tests by functionality
- Use descriptive test names that reflect the behavior being tested

### Test Isolation

- Use the transaction rollback feature to isolate tests
- Control event dispatching to avoid side effects
- Use different auth contexts to test different scenarios

### Test Coverage

- Test happy paths and error cases
- Test with different authentication contexts
- Test event publishing and handling

### Test Performance

- Use in-memory repositories for faster tests
- Avoid unnecessary database operations
- Use the transaction rollback feature to speed up tests

## Example: Complete Test Suite

```ruby
# spec/services/user_service_spec.rb
RSpec.describe UserService, type: :service do
  describe "#create_user" do
    it "creates a user" do
      user = service.create_user(name: "John", email: "john@example.com")
      expect(user.name).to eq("John")
      expect(user.email).to eq("john@example.com")
    end

    it "publishes a user created event" do
      expect {
        service.create_user(name: "John", email: "john@example.com")
      }.to publish_resource_event(
        resource_type: "users",
        event: "created"
      )
    end

    it "validates user attributes" do
      expect {
        service.create_user(name: "", email: "john@example.com")
      }.to raise_error(Verse::Error::ValidationFailed)
    end
  end

  describe "#get_users" do
    before do
      # Create test users
      service.create_user(name: "John", email: "john@example.com")
      service.create_user(name: "Jane", email: "jane@example.com")
    end

    it "returns all users for system context" do
      users = service.get_users
      expect(users.count).to eq(2)
    end

    it "returns limited users for user context" do
      as :user do
        users = service.get_users
        expect(users.count).to eq(1)
        expect(users.first.id).to eq(current_auth_context.metadata[:user_id])
      end
    end
  end
end

# spec/expositions/user_exposition_spec.rb
RSpec.describe UserExposition, type: :exposition do
  describe "GET /users" do
    before do
      # Create test users
      create_user(name: "John", email: "john@example.com")
      create_user(name: "Jane", email: "jane@example.com")
    end

    it "returns users" do
      get "/users"
      expect(response.status).to eq(200)
      expect(response.body[:data].count).to eq(2)
    end

    it "returns limited users for user context" do
      as :user do
        get "/users"
        expect(response.status).to eq(200)
        expect(response.body[:data].count).to eq(1)
      end
    end
  end

  describe "POST /users" do
    it "creates a user" do
      post "/users", { name: "John", email: "john@example.com" }
      expect(response.status).to eq(201)
      expect(response.body[:data][:name]).to eq("John")
    end

    it "returns validation errors" do
      post "/users", { name: "", email: "john@example.com" }
      expect(response.status).to eq(422)
      expect(response.body[:errors]).to be_present
    end
  end
end
