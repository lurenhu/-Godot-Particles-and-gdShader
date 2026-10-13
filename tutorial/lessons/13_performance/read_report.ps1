param([Parameter(Mandatory=$true)][string]$ReportPath)
$report = Get-Content -LiteralPath $ReportPath -Raw | ConvertFrom-Json
"Engine=$($report.engine) Driver=$($report.driver) GPU=$($report.gpu)"
"Size=$($report.viewport_size -join 'x') SmokeOnly=$($report.smoke_only) Aborted=$($report.aborted)"
$report.rows | ForEach-Object {
    [pscustomobject]@{
        Case = $_.case
        Round = $_.repeat
        FrameMedianMs = $_.wall.median_ms
        FrameP95Ms = $_.wall.p95_ms
        ViewportGpuMs = $_.viewport_gpu.median_ms
        GpuValidSamples = $_.viewport_gpu.valid_n
    }
} | Format-Table -AutoSize
