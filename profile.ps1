# dotnet suggest shell start
if (Get-Command "dotnet-suggest" -errorAction SilentlyContinue) {
    $availableToComplete = (dotnet-suggest list) | Out-String
    $availableToCompleteArray = $availableToComplete.Split(
        [Environment]::NewLine,
        [System.StringSplitOptions]::RemoveEmptyEntries
    )

    Register-ArgumentCompleter -Native -CommandName $availableToCompleteArray -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $fullpath = (Get-Command $commandAst.CommandElements[0]).Source

        $arguments = $commandAst.Extent.ToString().Replace('"', '\"')
        dotnet-suggest get -e $fullpath --position $cursorPosition -- "$arguments" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
else {
    "Unable to provide System.CommandLine tab completion support unless the [dotnet-suggest] tool is first installed."
    "See the following for tool installation: https://www.nuget.org/packages/dotnet-suggest"
}

$env:DOTNET_SUGGEST_SCRIPT_VERSION = "1.0.2"
# dotnet suggest script end

oh-my-posh init pwsh --config $HOME/code/omp-themes/alpha.omp.json | Invoke-Expression
$env:POSH_GIT_ENABLED = $true

Set-PSReadLineOption -EditMode Emacs
if ($IsMacOS) {
    Set-PSReadLineKeyHandler -Chord Alt+Spacebar -Function AcceptSuggestion
} else {
    Set-PSReadLineKeyHandler -Chord Ctrl+Spacebar -Function AcceptSuggestion
}

function Get-JwtClaims {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $jwt
    )

    $encodedClaims = $jwt.Split('.') | Select-Object -Index 1
    $encodedClaims = switch ($encodedClaims.Length % 4) {
        2 { $encodedClaims + '==' }
        3 { $encodedClaims + '=' }
        default { $encodedClaims }
    }

    [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String($encodedClaims)
    ) | ConvertFrom-Json
}

function Remove-LocalBranchesWithMissingUpstream {
    git branch -l --format '%(refname:short) %(upstream:track)'
        | ? { $_ -match "\[gone\]$" }
        | % { $_.split()
        | Select-Object -First 1 }
        | % { git branch -D $_ }
}
