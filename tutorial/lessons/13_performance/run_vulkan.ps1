param(
    [string]$GodotPath = 'G:\GodotEditor\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe',
    [switch]$Benchmark
)
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) { throw '请用 -GodotPath 指定 Godot 可执行文件。' }
$lessonProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$lessonArgs = @('--path', $lessonProject, '--rendering-driver', 'vulkan', '--resolution', '1200x800', 'res://tutorial/lessons/13_performance/performance_lab.tscn')
if ($Benchmark) { $lessonArgs += @('--', '--benchmark') }
& $GodotPath @lessonArgs
