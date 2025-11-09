# SePay Documentation Summary

## Overview
SePay is a Vietnamese payment automation service that helps businesses automate payments by sharing bank balance changes and automatically authenticating payments via bank transfers. This allows businesses to operate without payment gateway fees.

**Official Documentation**: https://docs.sepay.vn/
**Developer Portal**: https://developer.sepay.vn/

---

## Core Features

### 1. **Bank Balance Sharing**
- Automatically shares bank balance changes
- Self-authenticates payments via bank transfers
- No payment gateway fees

### 2. **Service Packages**
- Multiple service packages available
- Packages based on point of sale (POS)
- Configurable company settings

---

## Documentation Sections

### **Getting Started**
1. **Registration (Đăng ký SePay)**
   - How to register for SePay account
   - Account setup process

2. **Bank Account Setup**
   - Adding bank accounts (Thêm tài khoản ngân hàng)
   - Configuring bank accounts (Cấu hình TK ngân hàng)
   - Viewing transactions (Xem giao dịch)

3. **User Management**
   - Users & Permissions (Người dùng & Phân quyền)
   - Sub-accounts (Tài khoản phụ)

---

### **Company Configuration**
1. **Company Settings (Cấu hình công ty)**
   - General configuration (Cấu hình chung)
   - Service packages (Gói dịch vụ)
   - Invoice & Payment settings (Hóa đơn & thanh toán)
   - Balance change sharing (Chia sẻ biến động số dư)

---

### **Integration Options**

#### **Messaging Platforms**
- **Telegram Integration** (Tích hợp Telegram)
- **Lark Messenger Integration** (Tích hợp Lark Messenger)
- **Viber Integration** (Tích hợp Viber)

#### **Mobile & Hardware**
- **Mobile App** (Mobile App)
- **Payment Speaker Integration** (Tích hợp Loa thanh toán)

#### **E-commerce Platforms**
- **Web Integration** (Tích hợp web)
- **Shopify Integration** (Tích hợp Shopify)
- **Sapo Integration** (Tích hợp Sapo)
- **Haravan Integration** (Tích hợp Haravan)
- **WooCommerce Integration** (Tích hợp WooCommerce)

#### **Other Platforms**
- **GoHighLevel Integration** (Tích hợp GoHighLevel)
- **Google Sheets Integration** (Tích hợp Google Sheets)
- **HostBill Integration** (Tích hợp HostBill)

---

### **Programming & Integration**

#### **WebHooks**
- **WebHooks Integration** (Tích hợp WebHooks)
- **WebHooks Programming** (Lập trình WebHooks)
- Real-time payment notifications
- Transaction status updates

#### **QR Code**
- **Create & Embed QR Code** (Tạo & nhúng QR Code)
- Payment QR code generation
- QR code integration in applications

#### **OAuth2**
- OAuth2 authentication
- Secure API access
- Token management

#### **Transaction Simulation**
- **Transaction Simulation** (Giả lập giao dịch)
- Testing payment flows
- Development environment support

---

### **SePay API Documentation**

#### **API Overview**
- **API Introduction** (Giới thiệu API)
  - Overview of SePay API
  - API capabilities
  - Use cases for reconciliation and transaction details

#### **API Token Management**
- **Create API Token** (Tạo API Token)
  - Authentication setup
  - Token generation
  - Security best practices

#### **Transaction API**
- **Transaction API** (API Giao dịch)
  - Query transaction details
  - List transactions
  - Count transactions
  - Filter and search transactions

#### **Bank Account API**
- **Bank Account API** (API Tài khoản ngân hàng)
  - List bank accounts
  - Query account details
  - Check account balance
  - Account information retrieval

#### **Virtual Account API (VA by Order)**
- **VA by Order API** (API VA theo Đơn hàng)
  - Create virtual account per order
  - Automatic payment verification
  - Order-specific payment accounts
  - Enhanced transaction accuracy and security

---

## Key API Endpoints (Expected Structure)

### Base URL
- Production: `https://api.sepay.vn` (expected)
- Documentation: Check official docs for actual endpoints

### Authentication
- OAuth2 flow
- API Token in headers: `Authorization: Bearer {token}`

### Common Endpoints
1. **Transactions**
   - `GET /api/transactions` - List transactions
   - `GET /api/transactions/{id}` - Get transaction details
   - `GET /api/transactions/count` - Count transactions

2. **Bank Accounts**
   - `GET /api/bank-accounts` - List bank accounts
   - `GET /api/bank-accounts/{id}` - Get account details
   - `GET /api/bank-accounts/{id}/balance` - Get balance

3. **Virtual Accounts (VA)**
   - `POST /api/va/create` - Create VA for order
   - `GET /api/va/{orderId}` - Get VA by order
   - `POST /api/va/{orderId}/verify` - Verify payment

4. **WebHooks**
   - `POST /webhooks` - Receive webhook events
   - Transaction status updates
   - Payment confirmations

---

## Integration Flow for Flutter App

### Step 1: Account Setup
1. Register SePay account
2. Add bank account(s)
3. Configure company settings
4. Enable required services

### Step 2: API Integration
1. Create API Token
2. Implement OAuth2 (if needed)
3. Set up WebHooks endpoint
4. Configure payment flow

### Step 3: Payment Flow
1. **Create Order** → Generate VA (Virtual Account)
2. **Display Payment Info** → Show QR code or bank details
3. **Wait for Payment** → Monitor via WebHooks or polling
4. **Verify Payment** → Confirm transaction via API
5. **Complete Order** → Update order status

### Step 4: WebHooks Setup
1. Create webhook endpoint in your backend
2. Register webhook URL with SePay
3. Handle payment notifications
4. Update order status in real-time

---

## Comparison with Stripe (Current Implementation)

| Feature | Stripe | SePay |
|---------|--------|-------|
| Payment Method | Credit/Debit Cards | Bank Transfer |
| Fees | Transaction fees | No gateway fees |
| Currency | Multiple (USD, etc.) | VND (Vietnamese Dong) |
| Region | Global | Vietnam |
| Integration | SDK available | API-based |
| Real-time | Yes | Yes (via WebHooks) |
| QR Code | Limited | Native support |

---

## Implementation Considerations

### Advantages of SePay
- ✅ No payment gateway fees
- ✅ Native Vietnam market support
- ✅ Bank transfer (familiar to Vietnamese users)
- ✅ QR code support
- ✅ WebHook integration
- ✅ Virtual Account per order

### Considerations
- ⚠️ Vietnam-focused (VND currency)
- ⚠️ Requires bank account setup
- ⚠️ Payment confirmation delay (bank transfer time)
- ⚠️ May need backend server for WebHooks
- ⚠️ Different flow than Stripe (not instant)

---

## Next Steps for Integration

1. **Review API Documentation**
   - Visit https://docs.sepay.vn/ for detailed API docs
   - Check https://developer.sepay.vn/ for SDK and examples

2. **Create SePay Service**
   - Similar to `StripeServices` class
   - Implement API calls using Dio
   - Handle authentication

3. **Implement Payment Flow**
   - Create VA for orders
   - Display payment QR code/details
   - Poll or use WebHooks for payment confirmation

4. **Backend Integration** (if needed)
   - Set up WebHook endpoint
   - Handle payment notifications
   - Update order status

5. **Testing**
   - Use transaction simulation
   - Test in development environment
   - Verify WebHook integration

---

## Resources

- **Official Documentation**: https://docs.sepay.vn/
- **Developer Portal**: https://developer.sepay.vn/
- **Support**: Available via Facebook Messenger, Telegram, Hotline
- **Video Tutorials**: YouTube channel available

---

## Notes

- All documentation is in Vietnamese
- API endpoints and authentication details should be verified from official documentation
- WebHooks require a publicly accessible endpoint (consider using Firebase Functions or similar)
- VA (Virtual Account) feature is key for order-specific payments

---

*Last Updated: Based on documentation available at https://docs.sepay.vn/*
*For the most current information, please refer to the official SePay documentation.*

