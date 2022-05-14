
/**
 * 
 * The mock prover has a very simple architecture.
 * - /generate-proof
 * - /verify-proof
 */

const express = require('express')
const bodyParser = require('body-parser');

const app = express();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// 
// Handlers.
// 

app.post('/generate-proof', (req, res) => {
    let pie = req.body.pie
    let proof = ""

    // This is probably wrong.
    // O(log^2 t) time to generate proof.
    let x = Math.log10(pie.length)
    x *= x

    for(let i = 0; i < x; i++) {
        proof = proof.concat("a")
    }

    let response = {
        proof,
    }

    res.send(proof)
});

module.exports = app
