module Verse
  module Plugin
    module Test
      class Plugin < Verse::Plugin::Base
      def initialize(*args)
        super(*args)
        @actions = []
      end

      def on_init
        @actions << :init
      end

      def on_start
        @actions << :start
      end

      def on_stop
        @actions << :stop
      end

      def on_finalize
        @actions << :finalize
      end

      def on_spec_helper_load
        @actions << :spec_helper_load
      end

      def on_rake
        @actions << :rake
      end
      end
    end

    module PluginWithDependencies
      class Plugin < Verse::Plugin::Base
        def self.action
          @@action
        end

        def dependencies
          [:dependent_plugin]
        end

        def on_start
          @@action = dependent_plugin.do_something
        end
      end
    end

    module DependentPlugin
      class Plugin < Verse::Plugin::Base
        def do_something
          :plugin
        end
      end
    end

    module DependentPlugin2
      class Plugin < Verse::Plugin::Base
        def do_something
          :other_plugin
        end
      end
    end


  end
end
