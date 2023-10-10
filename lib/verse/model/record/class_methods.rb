# frozen_string_literal: true

module Verse
  module Model
    module Record
      module ClassMethods
        attr_accessor :record_root_path, :repositories_root_path

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

        def relation(name, array: false, &block)
          @relations[name] = Relation.new(name, array: array, &block)

          define_method(name) do
            if array
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
        # @param foreign_key [Symbol] the foreign key of the relation
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
        def belongs_to(relation_name, primary_key: nil, foreign_key: nil, repository: nil, record: nil, **opts)
          foreign_key ||= "#{relation_name}_id"

          root = name.split(/::[^:]+$/).first
          repository ||= "#{root}::#{StringUtil.camelize(relation_name.to_s)}Repository"

          relation relation_name, array: false do |collection, auth_context, sub_included|
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
                }.compact
              },
              included: sub_included,
              record: record
            )

            [
              included, # the list we store
              lambda do |inc_record|
                inc_record.fetch(primary_key.to_s) do
                  raise "[belongs_to #{name}:#{relation_name}] primary key not found: #{primary_key}"
                end.to_s
              end, # Create index key
              lambda do |inc_record| # Acces index key
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
        def has_many(relation_name, primary_key: nil, foreign_key: nil, repository: nil, record: nil, **opts) # rubocop:disable Naming/PredicateName
          foreign_key ||= "#{Verse.inflector.singularize(type)}_id"

          root = name.split(/::[^:]+$/).first
          repository ||= "#{root}::#{StringUtil.camelize(Verse.inflector.singularize(relation_name.to_s))}Repository"

          relation relation_name, array: true do |collection, auth_context, sub_included|
            repository = Reflection.constantize(repository) if repository.is_a?(String)
            record ||= repository.model_class
            record = Reflection.constantize(record) if record.is_a?(String)
            primary_key ||= record.primary_key

            included = repository.new(
              auth_context
            ).index(
              {
                "#{foreign_key}__in" => collection.map{ |x|
                  condition = opts[:if]
                  next if condition && !condition.call(x)

                  # check key_type using model structure
                  pkey_info = record.fields[primary_key]

                  Verse::Model::Record::Converter.convert(
                    x[primary_key.to_sym],
                    pkey_info[:type]
                  )
                }.compact
              },
              included: sub_included,
              record: record
            )

            [
              included,
              lambda do |inc_record|
                inc_record.fetch(foreign_key.to_s) do
                  raise "[belongs_to #{name}:#{relation_name}] primary key not found: #{foreign_key}"
                end.to_s
              end, # Create index key
              lambda do |inc_record| # Acces index key
                inc_record.fetch(primary_key.to_s) do
                  raise "[belongs_to #{name}:#{relation_name}] foreign key not found: #{primary_key}"
                end.to_s
              end
            ]
          end
        end

        def has_one(relation_name, primary_key: nil, foreign_key: nil, repository: nil, **opts) # rubocop:disable Naming/PredicateName
          foreign_key ||= "#{Verse.inflector.singularize(type)}_id".to_sym
          primary_key ||= self.primary_key.to_sym

          root = name.split(/::[^:]+$/).first

          repository ||= "#{root}::#{StringUtil.camelize(relation_name.to_s)}Repository"

          relation relation_name, array: false do |collection, auth_context, sub_included|
            repository = Reflection.constantize(repository) if repository.is_a?(String)

            included = repository.new(
              auth_context
            ).index(
              {
                "#{foreign_key}__in" => collection.map{ |x|
                  condition = opts[:if]
                  next if condition && !condition.call(x)

                  pkey_info = fields[primary_key]

                  Verse::Model::Record::Converter.convert(
                    x[primary_key],
                    pkey_info[:type]
                  )
                }.compact
              },
              included: sub_included
            )

            [
              included,
              lambda do |inc_record|
                inc_record.fetch(foreign_key.to_s) do
                  raise "[belongs_to #{name}:#{relation_name}] primary key not found: #{foreign_key}"
                end.to_s
              end, # Create index key
              lambda do |record| # Acces index key
                record.fetch(primary_key.to_s) do
                  raise "[belongs_to #{name}:#{relation_name}] foreign key not found: #{primary_key}"
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
        #     field :id, type: :integer, primary: true
        #     field :first_name, type: :string
        #     field :last_name, type: :string
        #
        #     field :password_digest, visible: false # tell renderer not to export it.
        #
        #     field :full_name do
        #       "#{first_name} #{last_name}"
        #     end
        #  end
        def field(name, type: :any, key: nil, primary: false, visible: true, &block)
          key ||= name.to_sym
          @fields[key] = { name: name, key: key, type: type, visible: visible }

          if primary
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

        def infer_record_type_by_class_name
          regexp = /(::)?([a-zA-Z0-9_]+)$/
          Verse.inflector.pluralize(
            StringUtil.underscore(
              name[regexp].gsub(regexp, "\\2").gsub(/(.?)Record$/, "\\1")
            )
          )
        end
      end
    end
  end
end
