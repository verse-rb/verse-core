# frozen_string_literal: true

module Verse
  module Plugin
    module Test
      class Plugin < Verse::Plugin::Base
        attr_reader :actions

        def initialize(*args)
          super(*args)
          @actions = []
        end

        def on_init
          @actions << :init
        end

        def on_start(mode)
          @actions << [:start, mode]
        end

        def on_stop
          @actions << :stop
        end

        def on_finalize
          @actions << :finalize
        end
      end
    end

    module PluginWithDependencies
      class Plugin < Verse::Plugin::Base
        attr_reader :action

        def dependencies
          %i<dependent_plugin>
        end

        def on_start(mode)
          @action = dependent_plugin.do_something
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
