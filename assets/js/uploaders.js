let Uploaders = {}

Uploaders.S3 = function (entries, onViewError) {
    entries.forEach(entry => {
        let xhr = new XMLHttpRequest()
        onViewError(() => xhr.abort())
        xhr.onload = () => xhr.status === 200 ? entry.progress(100) : entry.error()
        xhr.onerror = () => entry.error()

        xhr.upload.addEventListener("progress", (event) => {
            if (event.lengthComputable) {
                let percent = Math.round((event.loaded / event.total) * 100)
                if (percent < 100) { entry.progress(percent) }
            }
        })

        console.log("Uploading to S3:", entry.meta)
        let url = entry.meta.upload_url
        xhr.open("PUT", url, true)
        xhr.send(entry.file)
    })
}

export default Uploaders;

