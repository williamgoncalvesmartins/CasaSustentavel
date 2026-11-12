param([string]$TextFile, [string]$OutputFile)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Media.SpeechSynthesis.SpeechSynthesizer,Windows.Media.SpeechSynthesis,ContentType=WindowsRuntime]
$null = [Windows.Media.SpeechSynthesis.SpeechSynthesisStream,Windows.Media.SpeechSynthesis,ContentType=WindowsRuntime]
$voice = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices | Where-Object { $_.Language -eq 'pt-BR' -and $_.Gender -eq 1 } | Select-Object -First 1
if (!$voice) { throw 'VOZ FEMININA PT-BR INDISPONIVEL' }
$synth = New-Object Windows.Media.SpeechSynthesis.SpeechSynthesizer
$synth.Voice = $voice
$text = [System.IO.File]::ReadAllText($TextFile)
$escaped = [System.Security.SecurityElement]::Escape($text)
$operation = $synth.SynthesizeSsmlToStreamAsync('<speak version="1.0" xml:lang="pt-BR"><prosody rate="-8%" pitch="+5%">' + $escaped + '</prosody></speak>')
$method = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.IsGenericMethod } | Select-Object -First 1
$task = $method.MakeGenericMethod([Windows.Media.SpeechSynthesis.SpeechSynthesisStream]).Invoke($null,@($operation))
$task.Wait()
$stream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($task.Result)
$file = [System.IO.File]::Create($OutputFile + '.part')
$stream.CopyTo($file)
$file.Dispose()
$stream.Dispose()
$synth.Dispose()
[System.IO.File]::Move($OutputFile + '.part',$OutputFile)
