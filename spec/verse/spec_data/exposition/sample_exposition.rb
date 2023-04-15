class SampleExposition < Verse::Exposition::Base

  def self.something_done
    @@something_done
  end

  expose on_spec_hook({data: true}) do
    input do
      required(:name).filled(:string)
    end
  end
  def do_something
    @@something_done = true
  end

end