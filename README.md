# GizmoGlobe_client

## Cấu hình môi trường

1. Sao chép file `.env.example` thành `.env`:
```bash
cp .env.example .env
```

2. Điền các thông tin Firebase của bạn vào file `.env`

3. Tạo file `google-services.json`:
   - Trên Windows: Chạy script PowerShell:
   ```powershell
   .\scripts\generate_google_services.ps1
   ```
   - Trên Linux/Mac: Chạy script bash:
   ```bash
   chmod +x scripts/generate_google_services.sh
   ./scripts/generate_google_services.sh
   ```

4. Đảm bảo file `google-services.json` và `.env` đã được thêm vào `.gitignore`