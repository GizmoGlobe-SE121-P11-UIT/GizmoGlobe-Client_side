# Đọc file .env
$envContent = Get-Content ..\.env | Where-Object { $_ -match '^[^#]' }
$envVars = @{}
foreach ($line in $envContent) {
    if ($line -match '^([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Tạo nội dung cho google-services.json
$jsonContent = @"
{
  "project_info": {
    "project_number": "413433346211",
    "project_id": "$($envVars['FIREBASE_PROJECT_ID'])",
    "storage_bucket": "$($envVars['FIREBASE_STORAGE_BUCKET'])"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "$($envVars['FIREBASE_APP_ID'])",
        "android_client_info": {
          "package_name": "com.example.gizmoglobe_client"
        }
      },
      "oauth_client": [
        {
          "client_id": "$($envVars['FIREBASE_CLIENT_ID'])",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.gizmoglobe_client",
            "certificate_hash": "$($envVars['FIREBASE_CERTIFICATE_HASH'])"
          }
        }
      ],
      "api_key": [
        {
          "current_key": "$($envVars['FIREBASE_API_KEY'])"
        }
      ]
    }
  ],
  "configuration_version": "1"
}
"@

# Ghi nội dung vào file
$jsonContent | Out-File -FilePath "..\android\app\google-services.json" -Encoding UTF8

Write-Host "Đã tạo google-services.json thành công!" 