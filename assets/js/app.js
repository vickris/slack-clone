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

Hooks.FileUpload = {
  mounted() {
    const input = this.el
    const dropZone = document.querySelector(`[phx-drop-target="#${input.id}"]`)

    // Handle file selection via click
    input.addEventListener("change", (e) => {
      this.handleFiles(e.target.files)
    })

    // Handle drag-and-drop
    if (dropZone) {
      dropZone.addEventListener("dragover", (e) => {
        e.preventDefault()
        dropZone.classList.add("border-blue-500", "bg-blue-50")
      })

      dropZone.addEventListener("dragleave", () => {
        dropZone.classList.remove("border-blue-500", "bg-blue-50")
      })

      dropZone.addEventListener("drop", (e) => {
        e.preventDefault()
        dropZone.classList.remove("border-blue-500", "bg-blue-50")
        this.handleFiles(e.dataTransfer.files)
      })
    }
  },
  handleFiles(files) {
    const fileList = Array.from(files)
    console.log("Processing files:", fileList)

    // Validate files
    const validFiles = fileList.filter(file => file.size <= 10_000_000)
    if (validFiles.length !== fileList.length) {
      alert("Some files exceed 10MB limit")
    }

    // Create a new DataTransfer to assign files
    const dataTransfer = new DataTransfer()
    validFiles.forEach(file => dataTransfer.items.add(file))

    // Assign back to input
    this.el.files = dataTransfer.files

    // Manually trigger LiveView processing
    this.el.dispatchEvent(new Event("input", { bubbles: true }))
  }
}


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

