// The listener node takes transactions from the sequencer, executes them,
// and then flushes the writes to the storage layer.
// In future, this will be a distributed architecture, whereby there is a
// scheduler which determines which tx's can be executed in parallel. 