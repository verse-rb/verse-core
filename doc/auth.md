# Authentication & Authorization

The authentication and authorization system is a core component of the Verse framework, providing security and access control. This document explains how the auth system works and how to use it.

## Overview

The auth system in Verse Core consists of several key components:

- **Auth Context**: Represents the current user's authentication and authorization context
- **Scope DSL**: Provides a domain-specific language for defining authorization scopes
- **Role Backend**: Manages role-based access control

## Auth Context

The Auth Context (`Verse::Auth::Context`) represents the current user's authentication and authorization context. It is used to:

- Check if a user can perform an action on a resource
- Filter data based on user permissions
- Track who performed operations

### Creating an Auth Context

Auth contexts can be created in several ways:

| Method | Description | Example |
|--------|-------------|---------|
| `from_role` | Create a context from a role | `Verse::Auth::Context.from_role(:admin)` |
| `new` | Create a context with specific rights | `Verse::Auth::Context.new(["users.read.*"])` |
| `[]` | Get a predefined context | `Verse::Auth::Context[:system]` |

### Authorization Checks

The auth context provides methods for checking if a user can perform an action on a resource:

| Method | Description | Example |
|--------|-------------|---------|
| `can?` | Check if the user can perform an action | `context.can?(:read, :users)` |
| `can!` | Check and apply scoping | `context.can!(:read, :users) { ... }` |

## Rights Format

Rights are defined in the format `resource.action.scope`:

| Component | Description | Examples |
|-----------|-------------|----------|
| `resource` | The resource being accessed | `users`, `posts`, `*` (all) |
| `action` | The action being performed | `read`, `write`, `delete`, `*` (all) |
| `scope` | The scope of the access | `all`, `me`, `custom`, `*` (all) |

## Scope Types

The Scope DSL supports several scope types:

| Scope | Description | Example (assuming Sequel Repository) |
|-------|-------------|--------------------------------------|
| `all?` | Full access to the resource | `scope.all? { User.dataset }` |
| `me?` | Access to the user's own resources | `scope.me? { User.where(id: auth_context.metadata[:user_id]) }` |
| `custom?` | Custom scopes defined by the application | `scope.custom?(:admin) { |ids| User.where(id: ids) }` |
| `else?` | Fallback scope if no other scope matches | `scope.else? { User.where(false) }` |

## Using Auth in a Sequel Repository

In this documentation, we assume the use of a Sequel Repository for examples. The Sequel Repository is provided by the verse-sequel plugin and allows working with SQL databases.

### Implementing Scoped Access

In a Repository, the `scoped` method is used to apply authorization scopes. It will be called by most
CRUD operations to filter data based on the user's permissions.

```ruby
class UserRepository < Verse::Sequel::Repository
  # Override the scoped method to apply authorization
  def scoped(action)
    @auth_context.can!(action, :users) do |scope|
      # Full access for administrators
      scope.all? { dataset }

      # Access to specific users for managers
      scope.custom?(:manager) do |user_ids|
        dataset.where(id: user_ids)
      end

      # Access to own user record only
      scope.me? { dataset.where(id: @auth_context.metadata[:user_id]) }

      # No access for other cases
      scope.else? { dataset.where(false) }
    end
  end
end
```

### Scoping in CRUD Operations

The scoped method is used in CRUD operations to filter data:

| Operation | Scoping Example (in Sequel Repository) |
|-----------|---------------------------------------|
| Create | `def create(attributes); scoped(:create); super; end` |
| Read | `def find(id); super(id, scope: scoped(:read)); end` |
| Update | `def update(id, attributes); super(id, attributes, scope: scoped(:update)); end` |
| Delete | `def delete(id); super(id, scope: scoped(:delete)); end` |
| Index | `def index(filters); super(filters, scope: scoped(:read)); end` |

## Role Backend

The Role Backend (`Verse::Auth::SimpleRoleBackend`) manages role-based access control. It defines what rights each role has.

### Defining Roles

Roles are defined using a hash of role names to arrays of rights:

```ruby
Verse::Auth::SimpleRoleBackend.roles = {
  admin: ["*.*.*"],                    # Admin has full access
  user: ["users.read.*", "users.write.me"], # Users can read all users and write their own
  guest: ["users.read.all"]            # Guests can only read users
}
```

## Example: Complete Authorization Flow

| Component | Responsibility | Example Code |
|-----------|----------------|--------------|
| Exposition | Receives request and passes auth context | `def get_users; user_service.get_users; end` |
| Service | Passes auth context to repository | `def get_users; users.index({}); end` |
| Repository | Uses auth context to filter data | `def scoped(action); @auth_context.can!(action, :users) { ... }; end` |

## Best Practices

| Area | Recommendation |
|------|----------------|
| Auth Context | Pass to services and repositories |
| Role Design | Use principle of least privilege |
| Scoping | Define clear scopes for each resource |
| Testing | Test with different auth contexts |

## Common Patterns

### System Operations

For operations that need to bypass normal authorization:

```ruby
class AdminService < Verse::Service::Base
  use_system_repo users: UserRepository

  def delete_all_users
    users.delete_all # Uses system context
  end
end
```

### Custom Scopes

For fine-grained access control:

```ruby
# Create a context with custom scopes
context = Verse::Auth::Context.from_role(:manager, custom_scopes: {
  users: [1, 2, 3] # User IDs the manager has access to
})

# In the repository
scope.custom?(:manager) do |user_ids|
  dataset.where(id: user_ids)
end
```

### Marking Context as Checked

When bypassing security checks:

```ruby
def public_operation
  @auth_context.mark_as_checked!
  # Proceed with operation
end
