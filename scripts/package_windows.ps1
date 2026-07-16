param(
  [string]$Publisher = "CN=17Yerdna",
  [string]$BuildDirectory,
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
if (-not $BuildDirectory) {
  $BuildDirectory = Join-Path $projectRoot "build\windows\x64\runner\Release"
}
if (-not $OutputPath) {
  $OutputPath = Join-Path $projectRoot "build\release\LumenBiblia.msix"
}
$BuildDirectory = [IO.Path]::GetFullPath($BuildDirectory)
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
$staging = [IO.Path]::GetFullPath((Join-Path $projectRoot "build\windows\msix"))

if (-not $staging.StartsWith($projectRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "La carpeta temporal debe estar dentro del proyecto."
}
if (-not (Test-Path (Join-Path $BuildDirectory "lumen_biblia.exe"))) {
  throw "No existe el build Release. Ejecuta flutter build windows --release."
}
if ($Publisher -notmatch '^CN=[A-Za-z0-9 ._-]+$') {
  throw "Publisher inválido. Usa un valor como CN=17Yerdna."
}

$versionLine = Select-String -Path (Join-Path $projectRoot "pubspec.yaml") `
  -Pattern '^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
if (-not $versionLine) { throw "No se pudo leer la versión de pubspec.yaml." }
$match = $versionLine.Matches[0]
$version = "$($match.Groups[1].Value).$($match.Groups[2].Value).$($match.Groups[3].Value).$($match.Groups[4].Value)"

if (Test-Path $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null
Copy-Item -Path (Join-Path $BuildDirectory "*") -Destination $staging -Recurse
New-Item -ItemType Directory -Path (Join-Path $staging "Assets") | Out-Null

$manifest = Get-Content (Join-Path $projectRoot "windows\packaging\AppxManifest.xml") -Raw
$manifest = $manifest.Replace("__VERSION__", $version).Replace("__PUBLISHER__", $Publisher)
Set-Content -Path (Join-Path $staging "AppxManifest.xml") -Value $manifest -Encoding utf8

Add-Type -AssemblyName System.Drawing
$icon = [Drawing.Icon]::ExtractAssociatedIcon((Join-Path $BuildDirectory "lumen_biblia.exe"))
foreach ($asset in @(
  @{ Name = "StoreLogo.png"; Size = 50 },
  @{ Name = "Square44x44Logo.png"; Size = 44 },
  @{ Name = "Square150x150Logo.png"; Size = 150 }
)) {
  $bitmap = [Drawing.Bitmap]::new($asset.Size, $asset.Size)
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  $graphics.DrawImage($icon.ToBitmap(), 0, 0, $asset.Size, $asset.Size)
  $bitmap.Save(
    (Join-Path $staging "Assets\$($asset.Name)"),
    [Drawing.Imaging.ImageFormat]::Png
  )
  $graphics.Dispose()
  $bitmap.Dispose()
}
$icon.Dispose()

$makeAppx = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" `
  -Recurse -Filter makeappx.exe |
  Where-Object FullName -Match '\\x64\\makeappx\.exe$' |
  Sort-Object FullName -Descending |
  Select-Object -First 1 -ExpandProperty FullName
if (-not $makeAppx) { throw "MakeAppx no está instalado." }

New-Item -ItemType Directory -Path (Split-Path $OutputPath) -Force | Out-Null
& $makeAppx pack /d $staging /p $OutputPath /o
if ($LASTEXITCODE -ne 0) { throw "MakeAppx terminó con error $LASTEXITCODE." }
Remove-Item -LiteralPath $staging -Recurse -Force
Write-Host "MSIX creado: $OutputPath"
Write-Host "El paquete está sin firmar; firma el artefacto antes de distribuirlo."
