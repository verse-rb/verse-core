module ExpoClassMethods
  def on_spec_hook(some_data)
    SpecHook.new(self, some_data)
  end
end