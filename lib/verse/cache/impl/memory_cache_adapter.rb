# frozen_string_literal: true

require "monitor"

module Verse
  module Cache
    module Impl
      # Simple in-memory cache adapter that implements a
      # Least Recently Used (LRU) cache.
      class MemoryCacheAdapter
        include MonitorMixin

        attr_reader :size

        Node = Struct.new(:key, :value, :exp, :prev, :next) do
          def detach
            prev.next = self.next
            self.next.prev = prev
            self.prev = nil
            self.next = nil
            self
          end

          def move_to_head(head)
            # Head --> X
            # => Head --> self --> X
            previous = head.next
            previous.prev = self
            head.next = self
            self.prev = head
            self.next = previous
            self
          end
        end

        def initialize(capacity = 10_000)
          super()
          @capacity = capacity
          @size = 0
          @cache = {}
          @head = Node.new(nil, nil, nil)
          @tail = Node.new(nil, nil, nil)
          @head.next = @tail
          @tail.prev = @head
        end

        def fetch(key, selector, now: Time.now)
          synchronize do
            key_store = @cache.fetch(key) { return nil }
            node = key_store.fetch(selector) { return nil }

            expiration = node.exp
            if expiration && now.to_i >= expiration
              node.detach
              key_store.delete(selector)
              @cache.delete(key) if key_store.empty?
              @size -= 1
              return nil
            end

            node.detach.move_to_head(@head).value
          end
        end

        # rubocop:disable Naming/MethodParameterName
        def cache(key, selector, data, ex: nil)
          synchronize do
            key_store = @cache.fetch(key) do
              @cache[key] = {}
            end

            node = key_store[selector]
            if node
              node.detach
              node.value = data
              node.exp = ex ? (Time.now.to_i + ex) : nil
            else
              node = key_store[selector] = Node.new(
                [key, selector],
                data,
                ex ? (Time.now.to_i + ex) : nil
              )
              @size += 1
            end

            node.move_to_head(@head)

            if (@size > @capacity) && @tail.prev
              # Remove the least recently used item
              remove(*@tail.prev.key)
            end
          end
          data # Return the cached data
        end
        # rubocop:enable Naming/MethodParameterName

        def remove(key, selector)
          synchronize do
            key_store = @cache[key]
            return unless key_store

            node = key_store.delete(selector)
            return unless node

            node.detach
            @cache.delete(key) if key_store.empty?
            # Return cache size after removal
            @size -= 1
          end
        end

        def flush(key, selectors)
          synchronize do
            selectors_to_flush = selectors.is_a?(Array) ? selectors : [selectors]
            key_store = @cache[key]
            return unless key_store

            selectors_to_flush.each do |selector|
              if selector == "*"
                key_store.each_key { |sel| remove(key, sel) }
              else
                remove(key, selector)
              end
            end
          end
        end
      end
    end
  end
end