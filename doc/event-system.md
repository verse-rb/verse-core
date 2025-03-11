# Event System

The event system is a core component of the Verse framework, enabling communication between services through an event-driven architecture. This document explains how the event system works and how to use it.

## Overview

The event system consists of several key components:

- **Event Manager**: Manages event subscriptions and publishing
- **Event Message**: Represents an event with content, headers, and metadata
- **Event Dispatcher**: Controls when events are dispatched (primarily for testing)

## Event Manager

The Event Manager is responsible for:

- Subscribing to events
- Publishing events
- Handling request-reply patterns

Verse Core provides a pluggable event manager system, allowing different implementations to be used. The base implementation is `Verse::Event::Manager::Base`, which defines the interface that all event managers must implement.

### Event Manager Types

Verse Core includes the following event manager implementations:

- **Local**: A simple in-process event manager for testing and development
- **Redis**: (In verse-redis plugin) Uses Redis streams for event distribution

### Event Manager Modes

The event manager supports three modes of operation:

- **Broadcast Mode**: Events are shared across multiple instances of a service. Broadcasted messages do not require acknowledgement and are not guaranteed to be delivered.
- **Consumer Mode**: Events are consumed by only one instance of a service. In this mode, events should be persisted and guaranteed to be delivered at most to one service.
- **Command Mode**: Events require a reply. The output of the method bound to this mode will be sent back to the reply-to channel.

### Event Manager Interface

The event manager interface includes the following methods:

```ruby
# Start the event manager
def start; end

# Stop the event manager
def stop; end

# Publish an event related to a resource
def publish_resource_event(resource_type:, resource_id:, event:, payload:, headers: {}); end

# Publish a message to a channel
def publish(topic, payload, headers: {}, reply_to: nil); end

# Send a request to a specific topic and wait for a response
def request(topic, content, headers: {}, reply_to: nil, timeout: 0.5); end

# Send a request to multiple subscribers and collect responses
def request_all(topic, content, headers: {}, reply_to: nil, timeout: 0.5); end

# Subscribe to a specific topic
def subscribe(topic, mode: Manager::MODE_CONSUMER, &block); end

# Subscribe to events related to a specific resource type
def subscribe_resource_event(resource_type:, event:, mode: Manager::MODE_CONSUMER, &block); end
```

## Event Message

The Event Message represents an event with:

- **Content**: The payload of the event
- **Headers**: Metadata about the event
- **Reply-to**: Channel to send replies to (if any)
- **Manager**: Reference to the event manager
- **Channel**: The channel the event was received on

### Message Interface

The message interface includes:

```ruby
# Reply to the message
def reply(content, headers: {}); end

# Check if the message can be replied to
def allow_reply?; end

# Acknowledge receipt of the message
def ack; end
```

## Event Dispatcher

The Event Dispatcher is primarily designed for testing purposes. It controls when events are dispatched, which is particularly useful in test environments where you need precise control over event timing. It supports three modes:

- **Immediate**: Events are dispatched immediately when triggered
- **On Commit**: Events are dispatched after a transaction is committed (default)
- **Manual**: Events are dispatched manually using the `dispatch!` method

This component is especially valuable when testing with transactional databases, as it allows you to control whether events are dispatched before or after a transaction is committed, or manually at a specific point in your test.

### Dispatcher Interface

The dispatcher interface includes:

```ruby
# Execute a block with manual event mode, then dispatch events
def execute_later(&block); end

# Register an event for later dispatch
def register_event(&block); end

# Dispatch registered events
def dispatch!; end

# Set the event dispatch mode
def event_mode=(mode); end
```

## Event Handling in Exposition Layer

Events in Verse are typically caught and handled in the exposition layer. The exposition layer provides a structured way to expose functionality and handle events from external sources or other services.

When an event is received, it's processed through the exposition layer's handler chain, which can include authentication, validation, and other middleware before reaching the actual event handler.

Example of handling events in an exposition endpoint:

```ruby
class MyExposition < Verse::Exposition::Base
  expose on_resource_event("users", "created")
  # This method will be called when a "users:created" event is received
  def handle_user_created(message, channel)
    user_data = message.content
    # Process the user creation event
    # ...
  end
end
```

This approach ensures that events are processed with the same security and validation as regular API requests.

## Using the Event System

### Publishing Events

To publish an event:

```ruby
# Publish a message to a channel
Verse.event_manager.publish("channel_name", { key: "value" })

# Publish a resource event
Verse.event_manager.publish_resource_event(
  resource_type: "users",
  resource_id: "123",
  event: "created",
  payload: { id: "123", name: "John" }
)
```

### Subscribing to Events

Usually, you subscribe to events in the exposition layer, but you can also subscribe to events directly in your services.

To subscribe to events:

```ruby
# Subscribe to a channel
Verse.event_manager.subscribe(topic: "channel_name") do |message, channel|
  # Handle the message
end

# Subscribe to resource events
Verse.event_manager.subscribe_resource_event(
  resource_type: "users",
  event: "created"
) do |message, channel|
  # Handle the message
end
```

### Request-Reply Pattern

To send a request and wait for a reply:

```ruby
# Send a request to a channel.
# The request will be caught by one subscriber only
response = Verse.event_manager.request(
  "channel_name",
  { key: "value" },
  timeout: 1.0
)

# Send a request to all subscribers (broadcast)
responses = Verse.event_manager.request_all(
  "channel_name",
  { key: "value" },
  timeout: 1.0
)
```

## Event System Configuration

The event system is configured through the Verse configuration system:

```yaml
em:
  adapter: :local # or :redis, etc.
  config:
    # Adapter-specific configuration
```

## Best Practices

- Use resource events for domain events
- Use channel-based events for system events
- Keep event payloads small and focused
- Handle event failures gracefully
- Use the appropriate event mode for your use case
- Use the exposition layer for structured event handling
