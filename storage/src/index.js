const app = require('./api-server')

async function run() {
    console.log('Starting storage node')

    // Run a HTTP server.
    const port = 3000
    app.listen(port, () => {
        console.log(`API server listening on http://localhost:${port}`)
    });
}

run().catch(ex => { throw ex })