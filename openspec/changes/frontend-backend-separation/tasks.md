## 1. Create ExecutorBackend Node

- [ ] 1.1 Create `addons/hasturoperationgd/executor_backend.gd` extending `Node` with `class_name ExecutorBackend`
- [ ] 1.2 Implement `_init()` / `_ready()` to create `GDScriptExecutor`, read broker host/port from settings, and create `BrokerClient`
- [ ] 1.3 Implement `_process(delta)` to call `_broker_client.poll(delta)`
- [ ] 1.4 Implement `_notification()` / cleanup to call `disconnect_client()` on the `BrokerClient` when freed
- [ ] 1.5 Define signals: `connection_state_changed(connected: bool, executor_id: String)`, `execution_completed(entry: Dictionary)`, `history_cleared()`
- [ ] 1.6 Connect `BrokerClient` signals (`connection_established`, `connection_lost`, `remote_execution_completed`) and re-emit as backend signals
- [ ] 1.7 Implement `execute_code(code: String) -> Dictionary` that runs code on the local executor, builds a history entry with `source: "local"`, adds it to history, and emits `execution_completed`
- [ ] 1.8 Implement execution history storage: `_history` array (max 50 entries), `get_history() -> Array`, `clear_history()` method that clears and emits `history_cleared`
- [ ] 1.9 Handle remote execution: on `BrokerClient.remote_execution_completed` signal, build history entry with `source: "remote"`, add to history, emit `execution_completed`

## 2. Refactor Plugin Entry Point

- [ ] 2.1 Update `hasturoperationgd.gd` `_enter_tree()` to create `ExecutorBackend` first and add it as a child node
- [ ] 2.2 Pass the `ExecutorBackend` reference to the dock panel when creating it
- [ ] 2.3 Update `_exit_tree()` to remove dock first, then free the `ExecutorBackend` (remove child + queue_free), removing the old `_get_broker_client()` backdoor pattern

## 3. Refactor ExecutorDock to Pure UI

- [ ] 3.1 Remove `_broker_client` variable and `_get_broker_client()` method from `executor_dock.gd`
- [ ] 3.2 Remove `_executor` variable and `GDScriptExecutor` creation from `_ready()`
- [ ] 3.3 Add `_backend: ExecutorBackend` variable, set via an `initialize(backend: ExecutorBackend)` method or constructor approach
- [ ] 3.4 Replace `_process()` polling of broker client with nothing (backend handles its own polling)
- [ ] 3.5 Connect dock signals to backend: `backend.connection_state_changed` -> update status label, `backend.execution_completed` -> refresh history list, `backend.history_cleared` -> clear history list
- [ ] 3.6 Update `_on_execute_pressed()` to call `_backend.execute_code(code)` and display the returned result
- [ ] 3.7 Update `_on_connection_established()` and `_on_connection_lost()` to be handlers for `backend.connection_state_changed` signal instead of direct `BrokerClient` signals
- [ ] 3.8 Update `_refresh_history_list()` to read from `_backend.get_history()` instead of local `_history` array
- [ ] 3.9 Update `_on_clear_history()` to call `_backend.clear_history()` instead of clearing local array
- [ ] 3.10 Remove local `_history` array and `_max_history` from dock (history is now in backend)

## 4. Verify and Test

- [ ] 4.1 Verify plugin loads without errors and dock panel displays correctly
- [ ] 4.2 Verify local code execution works through the backend
- [ ] 4.3 Verify broker connection status updates in the dock via backend signals
- [ ] 4.4 Verify remote execution from broker-server is received and executed by the backend
- [ ] 4.5 Verify execution history displays correctly and is sourced from the backend
- [ ] 4.6 Verify plugin cleanup frees backend and disconnects broker client properly
