const express = require('express')
const bodyParser = require('body-parser');

class APIServer {
    static async create(node) {
        const app = express();

        app.use(bodyParser.urlencoded({ extended: false }));
        app.use(bodyParser.json());

        // Endpoints.
        app.post('/write', async (req, res) => {
            const {
                proof,
                txHash,
                txOutput,
            } = req.body

            await node.write({
                proof,
                txHash,
                txOutput
            })

            res.send({})
        });

        return app
    }
}

module.exports = {
    APIServer
}