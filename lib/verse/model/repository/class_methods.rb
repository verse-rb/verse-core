# frozen_string_literal: true

module Verse
  module Model
    module Repository
      module ClassMethods
        attr_writer :model_class
        attr_accessor :custom_filters, :encoders

        include Verse::Util

        def managed_methods
          @managed_methods ||= Set.new
        end

        def __default_record_name__
          name.gsub(/Repository$/, "Record")
        end

        # The record class used by this repository.
        # This is used to create new instances of the model.
        def model_class
          @model_class || Reflection.constantize(__default_record_name__)
        end

        def managed_methods?(name)
          @managed_methods[name]
        end

        # Set a custom name for the table/namespace used by this repository.
        def table(name = nil)
          @table = name if name
          @table || self.name.underscore.gsub(/_repository$/, "")
        end

        def resource(name = nil, aggregate: true, root: Verse.service_name)
          if aggregate.is_a?(String)
            @event_resource = [root, aggregate, name].compact.join(".")
            @iam_resource = [root, aggregate].compact.join(".")
          else
            @event_resource = @iam_resource = [root, name].compact.join(".")
          end
        end

        def event_resource
          @event_resource || [Verse.service_name, table].join(".")
        end

        def iam_resource
          @iam_resource || [Verse.service_name, table].join(".")
        end

        # Flag the next defined method as an event method.
        def event(name = nil, **opts)
          @next_method_mode = [:w, name, opts]
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
          define_method(method_name) do |*args|
            with_db_mode(:r){ method.bind(self).call(*args) }
          end
        end

        def define_event_method(method, method_name, _options = {})
          _, name, opts = @next_method_mode

          if opts[:creation]
            creation = true
          else
            index = opts.fetch(:key, 0)
          end

          define_method(method_name) do |*args|
            name ||= Verse.inflector.inflect_past(method_name)
            event_path = [self.class.event_resource, name].join(".")

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

                @event_cause = event_path

                if creation
                  result = method.bind(self).call(*args)

                  if result.class != Integer && result.class != String
                    raise "must returns a String or Integer which is the id of the newly created model, but #{result.class} given."
                  end

                  unless @disable_event
                    after_commit do
                      Verse.event_manager&.publish(event_path, {
                                                     resource_model: self.class.event_resource,
                                                     resource_id: result.to_s,
                                                     event: event_path,
                                                     args: args,
                                                     metadata: metadata,
                                                     created_at: Time.current
                                                   })
                    end
                  end

                else
                  id = args[index]
                  arg2 = args.dup
                  arg2.slice!(index)

                  result = method.bind(self).call(*args)

                  unless @disable_event
                    after_commit do
                      Verse.event_manager&.publish(event_path, {
                                                     resource_model: self.class.event_resource,
                                                     resource_id: id.to_s,
                                                     event: event_path,
                                                     args: arg2,
                                                     metadata: metadata,
                                                     created_at: Time.current
                                                   })
                    end
                  end

                end
              ensure
                @event_cause = old_event_cause # revert the cause.
              end

              result
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

        # Can be redefined by childs in case the primary key must be in a certain
        # form (hmmm MongoDb ObjectID?)
        def pkeyify(pkey)
          pkey
        end
      end
    end
  end
end
