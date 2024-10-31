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


const statusElementId = rawLink => `${btoa(rawLink.dataset.text)}-${rawLink.dataset.order}-status`

const collectRawLinks = () => Array.from(document.querySelectorAll('[phx-hook="LivingRawLink"]')).sort((a, b) => a.dataset.order - b.dataset.order);

const linkStatusTransformer = {
  name: 'link-highlighter',
  preprocess(code, options) {
    const rawLinks = collectRawLinks();
    options.decorations ||= []

    let offset = 0;

    for (const rawLink of rawLinks) {
      const text = rawLink.dataset.text;

      const index = code.indexOf(text, offset);

      if (index !== -1) {
        const end = index + text.length;

        options.decorations.push({
          start: index,
          end: end,
          properties: {
            id: statusElementId(rawLink),
            tabindex: rawLink.dataset.order,
            // "phx-click": "foo"
          },
        });

        offset = (end + 1)
      } else {
        console.error("failed to find text:", text)
      }
    }
  }
}

const statusData = status => {
  switch (status) {
    case "200":
      return ["link-status-green", "200 OK"];
    case "403":
      return ["link-status-yellow", "403 Not Allowed"];
    case "404":
      return ["link-status-red", "404 Not Found"];
    case "not_http_or_https":
      return ["gray", "No HTTP(S) URL"];
    default:
      console.error("unmatched status:", status)
      ["blue", "status not resolved"]
  }
}

let Hooks = {}

Hooks.LivingSource = {
  mounted() {
    this.updated();
  },
  updated() {
    let source = document.getElementById("basic_source").textContent;

    let living_source = window.highlighter.codeToHtml(source, {
      lang: 'html',
      theme: 'nord',
      transformers: [
        linkStatusTransformer
      ]
    })

    this.el.innerHTML = living_source;
  }
}

Hooks.LivingRawLink = {
  mounted() {
    const rawLink = this.el;

    rawLink.addEventListener("click", () => {
      document.getElementById(statusElementId(rawLink)).focus({ focusVisible: true });
    })
  },
  updated() {
    const rawLink = this.el;
    const status = rawLink.dataset.status;
    const statusElement = document.getElementById(statusElementId(rawLink));

    if (statusElement) {
      const [cssClass, title] = statusData(status);

      // should eventually remove "old" status classes
      statusElement.classList.add(cssClass);
      statusElement.title = title
    }
  }
}

window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
  // Enable server log streaming to client.
  // Disable with reloader.disableServerLogs()
  reloader.enableServerLogs()
  window.liveReloader = reloader
})

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

