# Qwen3.6 Local Model Stress Test Script
# Target: http://192.168.1.60:8033/v1

$BaseUrl = "http://192.168.1.60:8033/v1"
$Model = "Qwen3.6-35B-A3B-APEX-MTP-Balanced.gguf"
$Headers = @{
    "Authorization" = "Bearer sk-local"
    "Content-Type" = "application/json"
}

function Test-Request {
    param(
        [string]$Prompt,
        [int]$MaxTokens = 256,
        [string]$TestName = "Test"
    )
    
    $Body = @{
        model = $Model
        messages = @(
            @{role = "user"; content = $Prompt}
        )
        temperature = 0.7
        max_tokens = $MaxTokens
    } | ConvertTo-Json -Depth 3
    
    $StartTime = Get-Date
    try {
        $Response = Invoke-WebRequest -Uri "$BaseUrl/chat/completions" -Method POST -Headers $Headers -Body $Body -UseBasicParsing
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalMilliseconds
        
        $Json = $Response.Content | ConvertFrom-Json
        $Content = $Json.choices[0].message.content
        $TokensUsed = $Json.usage.total_tokens
        
        Write-Host "[$TestName] SUCCESS | Time: $Duration ms | Tokens: $TokensUsed"
        return @{
            Success = $true
            Duration = $Duration
            Tokens = $TokensUsed
            Content = $Content
        }
    }
    catch {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalMilliseconds
        Write-Host "[$TestName] FAILED | Time: $Duration ms | Error: $_"
        return @{
            Success = $false
            Duration = $Duration
            Error = $_
        }
    }
}

Write-Host "========================================"
Write-Host "  Qwen3.6 Local Model Stress Test"
Write-Host "========================================"
Write-Host ""

# Test 1: Continuous Request Test (10 times)
Write-Host "[Test 1] Continuous Request Test (10 requests)"
$Results1 = @()
1..10 | ForEach-Object {
    $Result = Test-Request -Prompt "Write a short poem about nature." -MaxTokens 100 -TestName "Continuous #$($_)"
    $Results1 += $Result
}
$SuccessRate1 = ($Results1 | Where-Object { $_.Success }).Count / $Results1.Count * 100
$AvgTime1 = ($Results1 | Where-Object { $_.Success } | Measure-Object -Property Duration -Average).Average
Write-Host "Result: Success Rate $SuccessRate1% | Avg Time $AvgTime1 ms"
Write-Host ""

# Test 2: Long Text Processing Test
Write-Host "[Test 2] Long Text Processing Test"
$LongPrompt = "Please write a detailed essay about the history of artificial intelligence, covering: 1) Early AI research in the 1950s, 2) Expert systems in the 1980s, 3) Machine learning in the 2000s, 4) Deep learning in the 2010s, 5) Current AI state in 2024. Write at least 500 words."
$Result2 = Test-Request -Prompt $LongPrompt -MaxTokens 1024 -TestName "Long Text"
Write-Host ""

# Test 3: Complex Reasoning Test
Write-Host "[Test 3] Complex Reasoning Test"
$ComplexPrompt = "Solve this step by step: A company has 150 employees. 40% are engineers, 30% are designers, rest are managers. If company hires 20 new engineers and 10 new designers, what is the new percentage of each role? Show calculation."
$Result3 = Test-Request -Prompt $ComplexPrompt -MaxTokens 512 -TestName "Complex Reasoning"
Write-Host ""

# Test 4: Code Generation Test
Write-Host "[Test 4] Code Generation Test"
$CodePrompt = "Write a Python function that calculates the Fibonacci sequence up to n terms. Include documentation and error handling."
$Result4 = Test-Request -Prompt $CodePrompt -MaxTokens 512 -TestName "Code Gen"
Write-Host ""

# Test 5: Chinese Processing Test
Write-Host "[Test 5] Chinese Processing Test"
$ChinesePrompt = "Please introduce yourself in Chinese language."
$Result5 = Test-Request -Prompt $ChinesePrompt -MaxTokens 512 -TestName "Chinese"
Write-Host ""

# Test 6: High Frequency Request Test (20 times)
Write-Host "[Test 6] High Frequency Request Test (20 requests)"
$Results6 = @()
1..20 | ForEach-Object {
    $Result = Test-Request -Prompt "What is the capital of France?" -MaxTokens 50 -TestName "HighFreq #$($_)"
    $Results6 += $Result
}
$SuccessRate6 = ($Results6 | Where-Object { $_.Success }).Count / $Results6.Count * 100
$AvgTime6 = ($Results6 | Where-Object { $_.Success } | Measure-Object -Property Duration -Average).Average
Write-Host "Result: Success Rate $SuccessRate6% | Avg Time $AvgTime6 ms"
Write-Host ""

# Summary
Write-Host "========================================"
Write-Host "  Test Results Summary"
Write-Host "========================================"

$AllResults = $Results1 + $Results6
$TotalRequests = $AllResults.Count
$TotalSuccess = ($AllResults | Where-Object { $_.Success }).Count
$TotalSuccessRate = $TotalSuccess / $TotalRequests * 100
$AvgResponseTime = ($AllResults | Where-Object { $_.Success } | Measure-Object -Property Duration -Average).Average
$MinResponseTime = ($AllResults | Where-Object { $_.Success } | Measure-Object -Property Duration -Minimum).Minimum
$MaxResponseTime = ($AllResults | Where-Object { $_.Success } | Measure-Object -Property Duration -Maximum).Maximum

Write-Host ""
Write-Host "Total Requests: $TotalRequests"
Write-Host "Successful Requests: $TotalSuccess"
Write-Host "Success Rate: $TotalSuccessRate%"
Write-Host "Avg Response Time: $AvgResponseTime ms"
Write-Host "Min Response Time: $MinResponseTime ms"
Write-Host "Max Response Time: $MaxResponseTime ms"
Write-Host ""

if ($TotalSuccessRate -ge 95) {
    Write-Host "PASS: Model is stable and ready for use!"
}
elseif ($TotalSuccessRate -ge 80) {
    Write-Host "WARNING: Model is mostly working but has occasional issues"
}
else {
    Write-Host "FAIL: Model is unstable, please check configuration"
}