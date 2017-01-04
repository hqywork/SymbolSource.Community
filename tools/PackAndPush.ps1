<#
    从 NuGet 官方网站下载最新版的 nuget.exe。
#>
function DownloadNuGet(){
    $url="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" # NuGet 官方下载地址
    $downloadFolder=[IO.Path]::GetFullPath(".nuget") # 下载位置路径
    $retries=6 # 重试次数

    # 如果下载位置路径不存在，则创建
    if(!(Test-Path $downloadFolder)){
        New-Item -Path "$downloadFolder" -Type directory | Out-Null
    }

    # 下载文件路径
    $downloadFilePath=[IO.Path]::Combine($downloadFolder, "nuget.exe")
    # 如果 nuget.exe 未下载，则下载
    if(!(Test-Path $downloadFilePath)){
        Write-Host "正在下载 nuget.exe..."

        while($true){
            try{
                Invoke-WebRequest $url -OutFile $downloadFilePath
                break;
            }
            catch{
                $exceptionMessage = $_.Exception.Message
                Write-Host "从 '$url' 下载失败：$exceptionMessage"

                if ($retries -gt 0) {
                    $retries--
                    Write-Host "等待 10 秒后重试。剩余次数：$retries"
                    Start-Sleep -Seconds 10
                }
                else 
                {
                    $exception = $_.Exception
                    throw $exception
                }
            }
        }
    }

    return $downloadFilePath
}

CD $PSScriptRoot

$nugetFeed="http://cst-upser:8181/nuget/CST/"
$nuspec="..\SymbolSource.Server.Basic.nuspec"
$nupkgDirectory="..\artifacts"

# 下载 nuget.exe
$nuget=DownloadNuGet

# 打包
Write-Host "正在包装 SymbolSource.Server.Basic.nupkg..."

&$nuget pack $nuspec -outputdirectory $nupkgDirectory

# 推送包
Write-Host "正在推送包 SymbolSource.Server.Basic 至 $nugetFeed..."

&$nuget push $nupkgDirectory\*.nupkg CST -Source $nugetFeed