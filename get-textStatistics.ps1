function get-textStatistics($path)
{
    Get-Content -Path $path |
    Measure-Object -Line -Character -Word
}