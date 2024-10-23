# You can find the new timestamped tags here: https://hub.docker.com/r/gitpod/workspace-base/tags
FROM gitpod/workspace-base:2024-10-23-18-11-15

ENV ASDF_VERSION=v0.14.1
ENV ASDF_DATA_DIR=${HOME}/.asdf

# setup asdf-vm: https://asdf-vm.com/guide/getting-started.html
RUN git clone --depth 1 https://github.com/asdf-vm/asdf.git ${ASDF_DATA_DIR} --branch ${ASDF_VERSION} \
    && echo '. ${ASDF_DATA_DIR}/asdf.sh' >> ${HOME}/.bashrc

# install and pin erlang: https://github.com/asdf-vm/asdf-erlang
RUN bash -ic "asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git && asdf plugin update erlang 826ad0e11d896caf1ffb59405949c2617cf60bbb"

# install and pin elixir: https://github.com/asdf-vm/asdf-elixir
RUN bash -ic "asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git && asdf plugin update elixir a4c42e10a7681afd4c87da144e9667865d5034c6"

# install and pin rust: https://github.com/code-lever/asdf-rust
RUN bash -ic "asdf plugin-add rust https://github.com/code-lever/asdf-rust.git && asdf plugin update rust 95acf4fe65df1de74fca502482b8f3ac5af73c05"

COPY .tool-versions ${HOME}/

RUN bash -ic "asdf install"

ENV HEX_VERSION=v2.1.1

# hex: https://github.com/hexpm/hex/releases
# rebar (matching version depending on elixir? -> see: https://github.com/elixir-lang/elixir/blob/cc9e9b29a7b473010ed17f894e6a576983a9c294/lib/mix/lib/mix/tasks/local.rebar.ex#L124)
RUN bash -ic "mix archive.install github hexpm/hex ref ${HEX_VERSION} --force && mix local.rebar --force"

# setup persistent bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && sudo mkdir /commandhistory \
    && sudo touch /commandhistory/.bash_history \
    && sudo chmod -R 777 /commandhistory \
    && echo "${SNIPPET}" >> "${HOME}/.bashrc"

# get inotify-tools for live reload from phoenix, see: https://hexdocs.pm/phoenix/installation.html#inotify-tools-for-linux-users
RUN sudo install-packages inotify-tools