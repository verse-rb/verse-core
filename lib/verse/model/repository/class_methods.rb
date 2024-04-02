# frozen_string_literal: true

require "set"

module Verse
  module Model
    module Repository
      module ClassMethods
        attr_writer :model_class, :table, :primary_key, :resource
        attr_accessor :custom_filters, :encoders, :dispatch_event_mode

        include Verse::Util

        def managed_methods
          @managed_methods ||= Set.new
        end

        def __default_record_name__
          name.gsub(/Repository$/, "Record")
        end

        # This is the record class that this repository is managing.
        # It is used to build new records object.
        # @return [Class] the record class for this repository
        def model_class
          @model_class ||= Reflection.constantize(__default_record_name__)
        end

        def managed_methods?(name)
          @managed_methods[name]
        end

        # Set a custom name for the table/namespace used by this repository.
        def table
          @table ||= Verse.inflector.pluralize(
            StringUtil.underscore(name).gsub(/_repository$/, "")
          )
        end

        def resource(_name = nil)
          @resource ||= [Verse.service_name, Verse.inflector.pluralize(table)].join(":")
        end

        # Flag the next defined method as an event method.
        def event(name: nil, creation: false, key: 0, metadata: {})
          @next_method_mode = [:w, name, creation, key, metadata]
        end

        def query
          @next_method_mode = [:r]
        end

        def custom_filter(name, &block)
          @custom_filters ||= {}
          @custom_filters[name.to_s] = block
        end

        def encoder(name, encoder)
          @encoders ||= {}
          @encoders[name.to_s] = encoder
        end

        def inherited(subklass)
          super
          subklass.model_class = @model_class
          subklass.custom_filters = @custom_filters&.dup
        end

        def define_query_method(method, method_name)
          define_method(method_name) do |*args, **opts|
            mode(:r) do
              method.bind(self).call(*args, **opts)
            end
          end
        end

        def define_event_method(method, method_name)
          _, name, creation, key, metadata = @next_method_mode

          define_method(method_name) do |*args|
            mode(:rw) do
              name ||= Verse.inflector.inflect_past(method_name)

              transaction do
                result = nil

                # store the event first
                old_event_cause = @event_cause
                begin
                  # detect whether the event is caused by another event. Example:
                  #
                  #   event
                  #   def trigger(resource, scope)
                  #     update(resource, triggered: true)
                  #   end
                  #
                  # This will run two events:
                  #  - updated(metadata: {cause: "domain.resource.triggered"})
                  #  - triggered(metadata: {})
                  #
                  metadata = @metadata.dup # duplicate because we might change metadata before commit.
                  metadata.merge!(cause: @event_cause) if @event_cause

                  if creation
                    result = method.bind(self).call(*args)

                    if result.class != Integer && result.class != String
                      raise "must returns a String or Integer which is the id of" \
                            " the newly created model, but #{result.class} given."
                    end


                    dispatch_event do
                      @event_cause = [self.class.resource, name]

                      Verse.publish_resource_event(
                        resource_type: self.class.resource,
                        resource_id: result.to_s,
                        event: name,
                        payload: {
                          args:,
                          metadata:
                        }
                      )
                    end

                  else
                    id = args[key]
                    arg2 = args.dup
                    arg2.slice!(key)

                    result = method.bind(self).call(*args)

                    dispatch_event do
                      @event_cause = [self.class.resource, name]

                      Verse.publish_resource_event(
                        resource_type: self.class.resource,
                        resource_id: id.to_s,
                        event: name,
                        payload: {
                          args: arg2,
                          metadata:
                        },
                      )
                    end

                  end
                ensure
                  @event_cause = old_event_cause # revert the cause.
                end

                result
              end
            end
          end
        end

        def method_added(method_name)
          super

          return if @next_method_mode.nil? || managed_methods.include?(method_name)

          managed_methods << method_name

          method = instance_method(method_name)

          case @next_method_mode.first
          when :r
            define_query_method(method, method_name)
          when :w
            define_event_method(method, method_name)
          end

          @next_method_mode = nil
        end

        def primary_key
          @primary_key ||= :id
        end
      end
    end
  end
end
