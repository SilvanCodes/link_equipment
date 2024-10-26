// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

import "../css/app.css"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

import { createHighlighter } from 'shiki'

// `createHighlighter` is async, it initializes the internal and
// loads the themes and languages specified.
(async () => {
  const highlighter = await createHighlighter({
    themes: ['nord'],
    langs: ['html'],
  });

  window.highlighter = highlighter;
})();

function findAllSubstringIndexes(str, substr) {
  const indexes = []
  let i = -1
  while ((i = str.indexOf(substr, i + 1)) !== -1)
    indexes.push(i)
  return indexes
}

const myTransformer = {
  name: 'link-highlighter',
  preprocess(code, options) {

    const words = ["Silvan"]
    options.decorations ||= []

    for (const word of words) {
      const indexes = findAllSubstringIndexes(code, word)
      for (const index of indexes) {
        options.decorations.push({
          start: index,
          end: index + word.length,
          properties: {
            style: "background: red;",
            title: "Silvan"
          },
        })
      }
    }
  }
}

let Hooks = {}

Hooks.LivingSource = {
  mounted() {
    let source = document.getElementById("basic_source").textContent;

    let living_source = window.highlighter.codeToHtml(source, {
      lang: 'html',
      theme: 'nord',
      transformers: [
        myTransformer
      ]
    })

    this.el.innerHTML = living_source;
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

