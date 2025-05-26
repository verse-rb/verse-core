# frozen_string_literal: true

module Verse
  module Model
    module Record
      module ClassMethods
        # Define the main module where the records and repositories are stored.
        # This is used to infer the type of the record.
        attr_accessor :model_root_path

        attr_reader :fields, :relations

        include Verse::Util

        # get or set the `type` of the record. Useful for some renderers.
        # If not set, it will be infered from the class name
        #
        # @example
        #   class UserRecord < Verse::Model::Record::Base
        #     type "individual_users" # if not declared, it will be infered as "users" from the class name
        #   end
        #
        def type(value = nil)
          if value
            @type = value
          else
            @type ||= infer_record_type_by_class_name
          end
        end

        def primary_key
          raise "primary_key in #{self} is not set" if @primary_key.nil?

          @primary_key
        end

        def relation(name, **opts, &block)
          @relations[name] = Relation.new(name, **opts, &block)

          define_method(name) do
            raise "relation `#{name}` is not loaded" unless @local_included.include?(name.to_s)

            if opts[:array]
              @relations[name.to_sym]
            else
              @relations[name.to_sym]&.first
            end
          end
        end

        # This is a belong to relation.
        #
        # This allow to avoid N+1 query.
        #
        # we will setup a macro belongs_to to repeat this code but for now we run out of time !
        # this is a good example of creating a custom relation
        # relation name, arity: :one|:many do |collection, auth_context, sub_included|
        #
        # returns:
        # an array with the collection of item fetched, and the indexing lambda method
        # used to detect and rebind the elements.
        #
        # @param relation_name [Symbol] the name of the relation
        # @param primary_key [Symbol] the primary key of the relation
        # @param foreign_key [Symbol] the foreign key of the relation. If not set, it will be
        #      inferred from the relation name and the repository name, e.g. PostRecord => post_id.
        # @param repository [String] the repository of the relation
        # @param record [String] the record of the relation
        # @param opts [Hash] the options of the relation
        #
        # @option opts [Proc] :if a proc to check if the relation should be included.
        #                     Used for example to include a relation only if a condition is met.
        #
        # @example
        #
        #  class Post < Verse::Model::Record::Base
        #     field :id, type: Integer, primary: true
        #     field :content
        #
        #     belongs_to :author, repository: "UserRepository", if: ->(author) { author[:type] != "bot" }
        #   end
        #
        def belongs_to(relation_name, primary_key: nil, foreign_key: nil, repository: nil, record: nil, filters: {}, **opts)
          # Try to infer the repository name from the class name:
          repository ||= infer_repository(relation_name)

          unless foreign_key
            begin
              repository = Reflection.constantize(repository) if repository.is_a?(String)
            rescue NameError
              # This is a bit annoying but we might find ourselves in a circular reference loop
              # and we can't infer the primary key name of the foreign record.
              # raise instead of guessing default `id` column should be easier to fix.
              raise "#{name} reference a repository which doesn't exists yet (#{repository}).\n" \
                    "Please setup manually the foreign_key option for the relation `#{relation_name}`."
            end

            foreign_key ||= "#{relation_name}_#{repository.primary_key}"
          end

          # define the foreign key field if not defined
          if @fields[foreign_key.to_sym].nil?
            field foreign_key, type: :any, visible: false
          end

          opts = opts.merge({
                              array: false,
                              type: :belongs_to,
                              foreign_key:,
                              primary_key:,
                              repository:,
                              record:,
                              filters:
                            })

          relation relation_name, **opts do |collection, auth_context, sub_included|
            repository = Reflection.constantize(repository) if repository.is_a?(String)
            record ||= repository.model_class
            record = Reflection.constantize(record) if record.is_a?(String)

            primary_key ||= record.primary_key

            included = repository.new(
              auth_context
            ).index(
              {
                "#{primary_key}__in" => collection.map{ |x|
                  condition = opts[:if]
                  next if condition && !condition.call(x)

                  # check key_type using model structure
                  pkey_info = record.fields.fetch(primary_key){ raise "primary key name not found: `#{primary_key}`" }

                  Verse::Model::Record::Converter.convert(x[foreign_key.to_sym], pkey_info[:type])
                }.compact,
                **filters
              },
              included: sub_included,
              record:
            )

            [
              included, # the list we store
              lambda do |inc_record|
                inc_record.fetch(primary_key.to_s) do
                  raise "[belongs_to #{name}:#{relation_name}] primary key not found: #{primary_key}"
                end.to_s
              end, # Create index key
              lambda do |inc_record| # Access index key
                inc_record.fetch(foreign_key.to_s) do
                  raise "[belongs_to #{name}:#{relation_name}] foreign key not found: #{foreign_key}"
                end.to_s
              end
            ]
          end
        end

        # Define a relation has-many between two records.
        #
        # @param relation_name [Symbol] the name of the relation
        # @param primary_key [Symbol] the primary key of the relation,
        #        which is by default inferred from the foreign record primary key definition.
        # @param foreign_key [Symbol] the foreign key of the relation,
        #      which is by default the name of the actual record + `_id`, e.g. user_id.
        # @param repository [String] the repository of the foreign relation.
        # @param record [String] the record class of the foreign relation.
        # @param opts [Hash] the options of the relation
        # @option opts [Proc] :if a proc called at aggregation to discard some relations.
        #
        # @example
        #   class UserRecord < Verse::Model::Record::Base
        #     has_many :published_posts, foreign_key: :author_id, if: ->(x) { x[:status] == "published" }
        #   end
        #
        def has_many(relation_name, primary_key: nil, foreign_key: nil, repository: nil, record: nil, filters: {}, **opts) # rubocop:disable Naming/PredicateName
          repository ||= infer_repository(Verse.inflector.singularize(relation_name.to_s))

          opts = opts.merge({
                              array: true,
                              type: :has_many,
                              foreign_key:,
                              primary_key:,
                              record:,
                              repository:,
                              filters:
                            })

          relation relation_name, **opts do |collection, auth_context, sub_included|
            repository = Reflection.constantize(repository) if repository.is_a?(String)
            record ||= repository.model_class
            record = Reflection.constantize(record) if record.is_a?(String)
            primary_key ||= self.primary_key
            foreign_key ||= [Verse.inflector.singularize(type), self.primary_key].join("_")

            included = repository.new(
              auth_context
            ).index(
              {
                "#{foreign_key}__in" => collection.map{ |x|
                  condition = opts[:if]
                  next if condition && !condition.call(x)

                  # check key_type using model structure
                  if !record.fields.key?(foreign_key.to_sym)
                    raise "foreign key name not found: `#{foreign_key}` on relation `#{relation_name}`."
                  end

                  pkey_info = record.fields[foreign_key.to_sym]

                  Verse::Model::Record::Converter.convert(
                    x[primary_key.to_sym],
                    pkey_info[:type]
                  )
                }.compact,
                **filters
              },
              included: sub_included,
              record:
            )

            [
              included,
              lambda do |inc_record|
                inc_record.fetch(foreign_key.to_s) do
                  raise "[has_many #{name}:#{relation_name}] primary key not found: #{foreign_key}"
                end.to_s
              end, # Create index key
              lambda do |inc_record| # Access index key
                inc_record.fetch(primary_key.to_s) do
                  raise "[has_many #{name}:#{relation_name}] foreign key not found: #{primary_key}"
                end.to_s
              end
            ]
          end
        end

        def has_one(relation_name, primary_key: nil, foreign_key: nil, repository: nil, record: nil, filters: {}, **opts) # rubocop:disable Naming/PredicateName
          repository ||= infer_repository(relation_name)

          opts = opts.merge({
                              array: false,
                              type: :has_one,
                              foreign_key:,
                              primary_key:,
                              record:,
                              repository:,
                              filters:
                            })

          relation relation_name, **opts do |collection, auth_context, sub_included|
            repository = Reflection.constantize(repository) if repository.is_a?(String)
            record ||= repository.model_class
            record = Reflection.constantize(record) if record.is_a?(String)
            primary_key ||= self.primary_key
            foreign_key ||= [Verse.inflector.singularize(type), self.primary_key].join("_")

            included = repository.new(
              auth_context
            ).index(
              {
                "#{foreign_key}__in" => collection.map{ |x|
                  condition = opts[:if]
                  next if condition && !condition.call(x)

                  # check key_type using model structure
                  pkey_info = record.fields[foreign_key.to_sym]

                  Verse::Model::Record::Converter.convert(
                    x[primary_key.to_sym],
                    pkey_info[:type]
                  )
                }.compact,
                **filters
              },
              included: sub_included,
              record:
            )

            [
              included,
              lambda do |inc_record|
                inc_record.fetch(foreign_key.to_s) do
                  raise "[has_one #{name}:#{relation_name}] primary key not found: #{foreign_key}"
                end.to_s
              end, # Create index key
              lambda do |inc_record| # Access index key
                inc_record.fetch(primary_key.to_s) do
                  raise "[has_one #{name}:#{relation_name}] foreign key not found: #{primary_key}"
                end.to_s
              end
            ]
          end
        end

        # define a field of the record
        #
        # @param name [Symbol] the name (method) of the field
        # @param type [Symbol] the type of the field (optional, any by default)
        # @param key [Symbol] the key of the field. key map to a column name (optional, name by default)
        # @param primary [Boolean] whether the field is the primary key of the record
        # @param visible [Boolean] whether the field should be exported in serialization
        #
        # @param block [Proc] optional block to call as getter for the field.
        # @example
        #
        #  class UserRecord < Verse::Model::Record::Base
        #     field :id, type: Integer, primary: true
        #     field :first_name, type: String
        #     field :last_name, type: String
        #
        #     field :password_digest, visible: false # tell renderer not to export it.
        #
        #     field :full_name do
        #       "#{first_name} #{last_name}"
        #     end
        #  end
        def field(name, type: :any, key: nil, primary: false, visible: true,
                  readonly: false, required: false, meta: {}, &block)
          key ||= name.to_sym

          @fields[key] = { name:, key:, type:, visible:, readonly:, required:, meta: }

          if primary
            raise "type unknown: #{type}" unless Converter.has_converter?(type)

            raise "field: primary key already defined: #{@primary_key}" if @primary_key

            @primary_key = key
          end

          block ||= -> { @fields[key] }

          define_method(name, &block)
        end

        # define a enum field of the record
        # @param name [Symbol] the name (method) of the field
        # @param values [Array] the values of the enum
        # @param field [Symbol] the name of the field underlying the enum (optional, name by default)
        #                       if the field is not found, it will be created
        # @param prefix [String] the prefix of the enum methods
        # @param suffix [String] the suffix of the enum methods
        #
        # @example
        #
        # class UserRecord < Verse::Model::Record::Base
        #   enum :status, [:active, :inactive], prefix: "is"
        # end
        #
        # user = UserRecord.new(status: :active)
        # user.is_active? # => true
        # user.is_inactive? # => false
        def enum(name, values, field: name, prefix: nil, suffix: nil)
          self.field(field) unless respond_to?(name)

          values.each do |value|
            method_name = [prefix, value, suffix].compact.join("_")

            raise "enum: redefinition of method #{method_name}?" if respond_to?(:"#{method_name}?")

            define_method(:"#{method_name}?") do
              send(name.to_sym) == value
            end
          end
        end

        protected

        # :nodoc:
        def infer_repository(relation_name)
          camelized_name = StringUtil.camelize(relation_name.to_s)
          case name
          when /::Repository$/
            # If the format of this record is `::Repository`, we assume the project is using
            # [Namespace]::[Model]::[Repository|Record] format:
            # e.g. `User::Record` => `Object::Repository`
            name.sub(/[^:]+::Repository$/, "#{camelized_name}::Repository")
          when /::[^:]+$/
            # If the format is `[Namespace]::[ModelRepository|ModelRecord]`, we assume the project is using
            # [Namespace]::[Model][Repository|Record] format:
            # e.g. `UserRecord` => `ObjectRepository`
            name.sub(/::[^:]+$/, "::#{camelized_name}Repository")
          else # In case there is no namespace, we, we simply use the class name
            "#{camelized_name}Repository"
          end
        end

        # :nodoc:
        # Follow format module/name_pluralized
        def infer_record_type_by_class_name
          # Remove the main module name if it exists:
          name = self.name
          name = name.sub("#{model_root_path}::", "") if model_root_path

          case name
          when /::Record$/
            # If the format of this record is `::Record`, we assume the project is using
            # [Namespace]::[Model]::[Repository|Record] format:
            # e.g. `User::Record` => `Object::Record`
            Verse::Util::StringUtil.underscore(
              Verse.inflector.pluralize(
                name.sub(/([^:]+)::Record$/, "\\1")
              )
            )
          else
            # If the format is `[Namespace]::[ModelRepository|ModelRecord]`, we assume the project is using
            # [Namespace]::[Model][Repository|Record] format:
            # e.g. `UserRecord` => `ObjectRecord`

            Verse::Util::StringUtil.underscore(
              Verse.inflector.pluralize(
                name.sub(/Record$/, "")
              )
            )
          end
        end
      end
    end
  end
end
