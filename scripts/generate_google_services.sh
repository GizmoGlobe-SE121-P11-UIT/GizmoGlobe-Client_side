#!/bin/bash

# Đọc các biến môi trường từ .env
source ../.env

# Tạo nội dung cho google-services.json
cat > ../android/app/google-services.json << EOF
{
  "project_info": {
    "project_number": "413433346211",
    "project_id": "$FIREBASE_PROJECT_ID",
    "storage_bucket": "$FIREBASE_STORAGE_BUCKET"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "$FIREBASE_APP_ID",
        "android_client_info": {
          "package_name": "com.example.gizmoglobe_client"
        }
      },
      "oauth_client": [
        {
          "client_id": "$FIREBASE_CLIENT_ID",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.gizmoglobe_client",
            "certificate_hash": "$FIREBASE_CERTIFICATE_HASH"
          }
        }
      ],
      "api_key": [
        {
          "current_key": "$FIREBASE_API_KEY"
        }
      ]
    }
  ],
  "configuration_version": "1"
}
EOF

echo "Đã tạo google-services.json thành công!" 