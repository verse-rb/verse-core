# frozen_string_literal: true

require "zlib"

module Verse
  module Util
    module Impl
      module Memory
        # Simple marshal serializer that compresses data using Zlib.
        # Beware that this serializer is not secure against deserialization attacks.
        # It is recommended to use this only with trusted data sources.
        class ZMarshalSerializer
          def serialize(object)
            payload = [Marshal::MAJOR_VERSION, Marshal::MINOR_VERSION, object]
            # Marshal the object and compress it using Zlib
            Zlib::Deflate.deflate(Marshal.dump(payload))
          end

          def deserialize(data)
            # Decompress the data and then unmarshal it
            return nil if data.nil? || data.empty?

            begin
              # rubocop:disable Security/MarshalLoad
              # As stated above, we are aware that Marshal.load can be dangerous
              # if the data is not trusted.
              major, minor, payload = Marshal.load(Zlib::Inflate.inflate(data))
              # rubocop:enable Security/MarshalLoad

              unless major == Marshal::MAJOR_VERSION && minor == Marshal::MINOR_VERSION
                raise ArgumentError, "Invalid payload (bad version)"
              end

              payload
            rescue TypeError, ArgumentError, Zlib::DataError => e
              raise Error::SerializationError, "Failed to deserialize data: #{e.message}"
            end
          end
        end
      end
    end
  end
end
