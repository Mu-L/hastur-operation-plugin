export interface ExecutorInfo {
	id: string
	project_name: string
	project_path: string
	editor_pid: number
	plugin_version: string
	editor_version: string
	supported_languages: string[]
	connected_at: string
	status: 'connected' | 'disconnected'
	type: 'editor' | 'game'
}

export interface TcpMessage {
	type: string
	data?: unknown
}

export interface ExecuteRequest {
	request_id: string
	code: string
	language: string
}

export interface ExecuteResult {
	request_id: string
	compile_success: boolean
	compile_error: string
	run_success: boolean
	run_error: string
	outputs: [string, string][]
}

export interface ApiResponse {
	success: boolean
	error?: string
	hint?: string
	data?: unknown
}
