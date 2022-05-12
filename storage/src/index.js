let { connect } = require('lotion')

let { state } = await connect(GCI)

let myBalance = await state.accounts[myAddress].balance