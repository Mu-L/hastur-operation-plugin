---
name: godot-remote-executor
description: |
  Execute GDScript code on a running Godot editor via the Hastur broker-server HTTP API. Use this skill whenever the user wants to manipulate a Godot editor remotely — creating/modifying scenes, adjusting node properties, running editor operations, inspecting project state, or any task that requires interacting with a live Godot editor instance. This works by sending GDScript code through the broker-server's REST API, which forwards it to a connected Hastur Executor plugin inside the Godot editor. Trigger this skill when the user mentions Godot, Godot editor, GDScript execution, scene manipulation, node operations, or any task involving controlling a Godot project remotely, even if they don't explicitly mention "broker" or "remote execution." Also use when the user asks to inspect, query, or modify anything in their Godot project while the editor is running.
---

# Godot Remote Executor

This skill enables you to execute arbitrary GDScript code on a running Godot editor instance through the Hastur broker-server. The broker-server acts as a bridge: you send HTTP requests to it, and it forwards the code to the Godot editor's Hastur Executor plugin via TCP.

## Prerequisites

Before you begin, you need two things from the user:

1. **Auth token** — The broker-server requires a Bearer token for authentication. Ask the user for it if not provided. It was printed to stdout when the broker-server started.
2. **Base URL** — Defaults to `http://localhost:5302`. The user may specify a different host/port.

Store these for the duration of the conversation:
- `HASTUR_AUTH_TOKEN` — the Bearer token
- `HASTUR_BASE_URL` — defaults to `http://localhost:5302`

## Step 0: Read GDScript Syntax Reference (Critical)

Before writing any GDScript code, read the GDScript syntax reference to avoid compilation errors. GDScript has Python-like indentation-based syntax but significant differences in typing, built-in types, and conventions.

Read this file first:
- `references/gdscript-syntax/gdscript_basics.rst.txt` — The core language reference (~2900 lines). Covers syntax, types, control flow, functions, classes, signals, exports, and all language constructs.

This is the single most important thing you can do to reduce errors. GDScript has many subtle differences from Python:
- Uses `:=` for type inference (not `:`)
- `var x: int` for typed variables
- `func` not `def`
- Indentation matters (tabs, not spaces)
- `@onready`, `@export`, `@tool` annotations
- Built-in types: `Vector2`, `Vector3`, `Color`, `Dictionary`, `Array`, etc.
- String formatting with `%` operator or `format()` method
- `match` instead of `switch`
- No list comprehensions (use `Array.map()` / `Array.filter()`)
- `for x in range(n)` or `for x in array`
- Signals declared with `signal` keyword
- `preload()` and `load()` for resources

For @GDScript built-in functions and annotations, read:
- `references/gdscript-syntax/class_@gdscript.rst.txt` — @GDScript annotation and function reference

For global scope functions (print, push_error, etc.), read:
- `references/gdscript-syntax/class_@globalscope.rst.txt` — @GlobalScope constants and functions

For code style conventions, read:
- `references/gdscript-syntax/gdscript_styleguide.rst.txt` — official style guide

## Step 1: Discover Connected Editors

First, check which Godot editors are connected to the broker-server. Run:

```bash
curl -s -H "Authorization: Bearer HASTUR_AUTH_TOKEN" HASTUR_BASE_URL/api/executors
```

The response looks like:
```json
{
  "success": true,
  "data": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "project_name": "my-game",
      "project_path": "C:/Users/dev/projects/my-game",
      "editor_pid": 12345,
      "plugin_version": "0.1",
      "editor_version": "4.6.0",
      "supported_languages": ["gdscript"],
      "connected_at": "2026-03-28T10:00:00.000Z",
      "status": "connected"
    }
  ]
}
```

If `data` is empty, the hint field will explain why — the user needs to enable the Hastur Executor plugin in their Godot editor.

Note the `id` (executor_id) for targeting specific editors.

## Step 2: Execute Code

Send GDScript code to a connected editor via POST request:

```bash
curl -s -X POST \
  -H "Authorization: Bearer HASTUR_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"code": "<GDScript code here>", "executor_id": "<executor id>"}' \
  HASTUR_BASE_URL/api/execute
```

### Targeting an Editor

You can identify the target editor in three ways (provide exactly one):
- `executor_id` — exact match, most reliable
- `project_name` — fuzzy substring match on the project name
- `project_path` — fuzzy substring match on the project path

When only one editor is connected, `project_name` is convenient. When multiple editors are connected, use `executor_id` to be precise.

### Execution Modes

The Hastur Executor supports two modes, determined automatically by whether the code contains `extends`:

**Snippet mode** (no `extends` keyword): Code is automatically wrapped in a `@tool extends RefCounted` class with a `run()` method. The `executeContext` variable is available as an `ExecutionContext` object with an `output(key, value)` method for returning structured results.

```gdscript
var node = get_tree().current_scene
executeContext.output("scene_name", node.name)
executeContext.output("child_count", str(node.get_child_count()))
```

**Full class mode** (contains `extends` keyword): Code must define a `func execute(executeContext):` method. Useful when you need to extend a specific type.

```gdscript
extends Node

func execute(executeContext):
    var root = get_tree().root
    executeContext.output("viewport_size", str(root.get_visible_rect().size))
```

### Understanding the Response

```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "compile_success": true,
    "compile_error": "",
    "run_success": true,
    "run_error": "",
    "outputs": [["key1", "value1"], ["key2", "value2"]]
  }
}
```

- `compile_success` — whether the code compiled
- `compile_error` — error message if compilation failed
- `run_success` — whether the code ran without errors
- `run_error` — runtime error message
- `outputs` — array of `[key, value]` pairs collected via `executeContext.output()`

## Step 3: Handle Errors

### Compilation Errors

If `compile_success` is false, read the `compile_error` message. Common causes:
- Syntax errors (wrong indentation, missing colons, Python-style syntax that doesn't work in GDScript)
- Type mismatches
- Undefined variables or functions

Re-read the GDScript syntax reference if you encounter repeated compilation errors. The most common mistakes are:
- Using spaces instead of tabs for indentation
- Using `def` instead of `func`
- Using Python-style string formatting (`f"..."`) instead of GDScript's `%s` or `format()`
- Using `True`/`False` instead of `true`/`false`
- Using `None` instead of `null`
- Forgetting `:` after `func`, `if`, `for`, `while`, `class`, `enum` declarations

### Runtime Errors

If `compile_success` is true but `run_success` is false, check `run_error`. The code compiled but crashed during execution. Outputs collected before the crash are still available in `outputs`.

### No Matching Executor (HTTP 404)

The executor_id/project_name/project_path didn't match any connected editor. Run `GET /api/executors` again to see what's available.

### Timeout (HTTP 504)

Code execution exceeded the 30-second limit. Simplify the code or break it into smaller steps.

## Step 4: Look Up Godot APIs as Needed

When you need to use Godot classes, methods, or properties that you're not fully confident about, look them up in the reference docs:

- **Class API reference**: Read `references/godot-docs/classes/class_<ClassName>.rst.txt` — for any Godot class (e.g., `class_node3d.rst.txt` for Node3D, `class_label3d.rst.txt` for Label3D)
- **Tutorials and guides**: Browse `references/godot-docs/tutorials/` for topic-specific guides
- **Scripting guides**: `references/godot-docs/tutorials/scripting/` for general scripting patterns

### Common Class File Naming Convention

Class files are named `class_<lowercaseclassname>.rst.txt`. For example:
- `class_node.rst.txt` — Node
- `class_node2d.rst.txt` — Node2D
- `class_node3d.rst.txt` — Node3D
- `class_control.rst.txt` — Control
- `class_button.rst.txt` — Button
- `class_label.rst.txt` — Label
- `class_sprite2d.rst.txt` — AnimatedSprite2D
- `class_camera3d.rst.txt` — Camera3D
- `class_ridigidbody3d.rst.txt` — RigidBody3D
- `class_inputevent.rst.txt` — InputEvent
- `class_resouce.rst.txt` — Resource
- `class_packedscene.rst.txt` — PackedScene
- `class_timer.rst.txt` — Timer
- `class_area2d.rst.txt` — Area2D
- `class_pathfollow2d.rst.txt` — PathFollow2D

Note: The `@` prefix classes are special:
- `class_@gdscript.rst.txt` — GDScript annotations and functions
- `class_@globalscope.rst.txt` — Global functions and constants

## Workflow Pattern

For complex tasks, follow this iterative pattern:

1. **Discover** — Query `/api/executors` to find available editors
2. **Read reference** — If unsure about GDScript syntax, read the syntax docs first
3. **Look up API** — If unsure about a Godot class/method, read the relevant class reference
4. **Write code** — Compose the GDScript snippet, using `executeContext.output()` to return results
5. **Execute** — Send via `POST /api/execute`
6. **Check result** — Parse the response, check compile_success and run_success
7. **Handle errors** — If errors, fix and retry
8. **Use outputs** — Extract information from the outputs array to inform next steps

## Important Notes

### Execution Context

The `executeContext` object has these characteristics:
- `output(key: String, value: String)` — call this to return data. Both arguments should be strings. The value is truncated if it exceeds the configured max char length (default 800).
- Output values that exceed the limit are truncated with a warning prefix

### Editor Plugin Environment

Code runs inside the Godot editor as a `@tool` script. This means:
- You have access to the editor's scene tree via `EditorScript` or `get_tree()`
- `EditorInterface` is available for editor operations
- The code runs on the main thread — avoid infinite loops or heavy computation
- Changes to nodes/scenes are reflected in real-time in the editor

### Snippet Mode Details

In snippet mode, your code is wrapped like this:
```gdscript
@tool
extends RefCounted

var executeContext

func run():
    <your code here, indented with tabs>
```

This means:
- You're inside a `RefCounted` instance, not a `Node`
- To access the scene tree, use `Engine.get_main_loop()` to get the `SceneTree`
- To access editor functionality, you may need `EditorInterface` (if available as a singleton)
- `executeContext` is set as a property before `run()` is called

### Accessing the Scene Tree from Snippets

Since snippets extend `RefCounted` (not `Node`), you need to access the scene tree differently:

```gdscript
var tree = Engine.get_main_loop() as SceneTree
var root = tree.root
var edited_scene = tree.edited_scene_root
```

### Output Best Practices

- Convert all values to strings before passing to `output()`: `str(value)`
- Use descriptive keys: `"node_count"`, `"scene_path"`, `"error_message"`
- For large outputs, be aware of the character limit per value
- If you need to return structured data, consider JSON-encoding it: `JSON.stringify(data)`

## Reference Files

### GDScript Syntax (read before writing code)
- `references/gdscript-syntax/gdscript_basics.rst.txt` — Core language reference
- `references/gdscript-syntax/gdscript_advanced.rst.txt` — Advanced features
- `references/gdscript-syntax/class_@gdscript.rst.txt` — @GDScript built-in functions/annotations
- `references/gdscript-syntax/class_@globalscope.rst.txt` — Global scope functions/constants
- `references/gdscript-syntax/gdscript_styleguide.rst.txt` — Style guide

### Godot API Reference (read as needed)
- `references/godot-docs/classes/class_*.rst.txt` — 1066 class reference files
- `references/godot-docs/tutorials/` — Guides and tutorials by topic
