param(
    [string]$GodotPath = 'G:\GodotEditor\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
)

if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw '找不到 Godot。请通过 -GodotPath 指定 Godot 4 可执行文件。'
}
$lessonProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
& $GodotPath --path $lessonProject --rendering-driver vulkan --resolution 1200x800 res://tutorial/lessons/12_interactions/interactions_lab.tscn
