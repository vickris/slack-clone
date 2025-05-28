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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"

import { LiveSocket } from "../../deps/phoenix_live_view"
import topbar from "../vendor/topbar"
import Uploaders from "./uploaders"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.MessageScroll = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight
  },
  updated() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

Hooks.ClearInput = {
  mounted() {
    console.log("Element has been mounted")
    this.el.addEventListener("submit", () => {
      setTimeout(() => {
        const input = this.el.querySelector('input[name="content"]');
        if (input) input.value = "";
      }, 0);
    });
  }
};

Hooks.DirectS3Upload = {
  mounted() {
    console.log("DirectS3Upload hook mounted=====")
    this.input = this.el.querySelector('input[type="file"]')
    console.log("File input element:", this.input)
    // Try to get the LiveView instance from the parent element if not found on input
    // Try to get the LiveView instance from the input, the element, or their parents
    this.view = this.input?.__view__ || this.el.__view__ || this.input?.closest("[data-phx-view]")?.__view__ || this.el.closest?.("[data-phx-view]")?.__view__
    console.log("LiveView instance:", this.view)
    console.log("File input:", this.input)
    if (!this.input) {
      console.error("No file input found in DirectS3Upload hook")
      return
    }

    // 1. Handle click-based file selection
    this.input.addEventListener("change", (e) => this.handleFiles(e.target.files))

    // 2. Setup drag-and-drop on parent element
    const dropZone = document.getElementById("dropzone")
    console.log("Drop zone:", dropZone)
    if (dropZone) {
      console.log("Drop zone found, setting up drag-and-drop=====")
        // Prevent default drag behaviors
        ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
          dropZone.addEventListener(eventName, preventDefaults, false)
        })

        // Highlight drop zone
        ;['dragenter', 'dragover'].forEach(eventName => {
          dropZone.addEventListener(eventName, highlight, false)
        })
        ;['dragleave', 'drop'].forEach(eventName => {
          dropZone.addEventListener(eventName, unhighlight, false)
        })

      // Handle dropped files
      dropZone.addEventListener('drop', (e) => {
        const dt = e.dataTransfer
        this.handleFiles(dt.files)
      })
    }
  },

  handleFiles(files) {
    console.log("Handling files:", files)
    const view = this.input.__view__
    console.log("LiveView instance: handling files", view)
    console.log("LiveView instance: handling files", this.el.__view__)
    if (!view) return

    Array.from(files).forEach(file => {
      // 1. Create LiveView upload entry
      const entry = view.getEntry(this.el, file.name)

      // 2. Validate before proceeding
      if (!entry || !entry.meta?.upload_url) {
        console.error("Missing upload metadata for", file.name)
        return
      }

      // 3. Direct S3 upload
      const xhr = new XMLHttpRequest()
      xhr.open("PUT", entry.meta.upload_url, true)
      xhr.setRequestHeader("Content-Type", file.type)

      xhr.upload.onprogress = (e) => {
        const percent = Math.round((e.loaded / e.total) * 100)
        view.pushFileProgress(this.el, entry.ref, percent)
      }

      xhr.onload = () => {
        if (xhr.status === 200) {
          view.pushFileProgress(this.el, entry.ref, 100)
        } else {
          view.pushFileProgress(this.el, entry.ref, { error: "Upload failed" })
        }
      }

      xhr.send(file)
    })
  }
}

// Helper functions
function preventDefaults(e) {
  e.preventDefault()
  e.stopPropagation()
}

function highlight(e) {
  e.currentTarget.classList.add('bg-blue-50', 'border-blue-400')
}

function unhighlight(e) {
  e.currentTarget.classList.remove('bg-blue-50', 'border-blue-400')
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  uploaders: Uploaders
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

