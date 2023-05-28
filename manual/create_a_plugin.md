# Create your own plugin

In verse, everything is a plugin.

## Lifecycle

- `on_init`
- `on_start`

Hooks in server mode:

- `on_stop`
- `on_finalize`

Hook during specs are running:

- `on_spec_helper_load`

Hook when Rake environment is called:

- `on_rake`