param(
    [string]$GodotPath = 'G:\GodotEditor\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe',
    [switch]$Benchmark,
    [switch]$Verify
)
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) { throw '请用 -GodotPath 指定 Godot 4 可执行文件。' }
if ($Benchmark -and $Verify) { throw 'Benchmark 与 Verify 请分别运行。' }
$lessonProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$lessonArgs = @('--path', $lessonProject, '--resolution', '1200x800', 'res://tutorial/lessons/14_capstone/capstone_lab.tscn')
if ($Benchmark) { $lessonArgs += @('--', '--benchmark') }
if ($Verify) { $lessonArgs += @('--', '--lesson-test') }
& $GodotPath @lessonArgs
