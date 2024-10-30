`mix phx.new . --database sqlite3 --binary-id --no-tailwind --verbose --no-mailer --no-gettext`

`export ERL_AFLAGS="-kernel shell_history enabled"`


## LiveView state handling concept

Idea:
- all permanent state is passed via URL
- every other state needs to be derivable from whats passed in url
- use a generic `to_form(params)` in handle_params to create state
- maybe initialize assigns to nil in `mount` if necessary
- actually assign individual assigns from url state once validated
- how to do form validation?
