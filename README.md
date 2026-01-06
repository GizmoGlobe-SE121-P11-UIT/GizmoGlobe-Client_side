# GizmoGlobe Client

A comprehensive Flutter-based e-commerce platform specializing in computer hardware components. GizmoGlobe provides a modern shopping experience with AI-powered chat assistance, PC builder tools, and seamless payment processing.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Key Features Details](#key-features-details)
- [Payment Integration](#payment-integration)
- [AI Chat Assistant](#ai-chat-assistant)
- [Platform Support](#platform-support)
- [Build & Deploy](#build--deploy)

## 🎯 Overview

GizmoGlobe is a cross-platform e-commerce application built with Flutter, focusing on computer hardware sales. The application supports both web and mobile platforms, offering features like product browsing, shopping cart management, AI-powered product recommendations, PC builder tools, and multiple payment methods.

## ✨ Features

### Core E-commerce Features
- **Product Catalog**: Browse and search through a comprehensive catalog of computer hardware (CPU, GPU, RAM, Storage, PSU, Mainboard)
- **Product Details**: Detailed product specifications, images, ratings, and reviews
- **Shopping Cart**: Add products, manage quantities, and proceed to checkout
- **Order Management**: Track orders through different statuses (To Ship, To Receive, Completed, Cancelled)
- **Favorites/Wishlist**: Save favorite products for later
- **Product Recommendations**: AI-powered personalized product recommendations
- **Advanced Filtering**: Filter products by category, manufacturer, price range, specifications

### AI-Powered Chat Assistant
- **Natural Language Processing**: Conversational AI using Google Gemini API
- **Product Search & Recommendations**: Ask questions about products in natural language
- **Cart Management**: Add products to cart via voice/text commands
- **Product Comparisons**: Compare multiple products based on specifications
- **Compatibility Checking**: Check hardware compatibility using Vertex AI
- **Smart Queries**: Support for promotions, bestsellers, price inquiries, and more

### PC Builder Tool
- **Configuration Builder**: Build custom PC configurations with compatibility checking
- **Multiple Sessions**: Save and manage multiple PC build sessions
- **PDF Export**: Generate PDF configurations for your builds
- **Cost Estimation**: Cost calculation for builds
- **Compatibility Validation**: Automatic compatibility checking between components

### Payment Integration
- **Stripe**: Credit/debit card payments
- **SePay**: Bank transfer payments (Vietnam)
- **COD (Cash on Delivery)**: Pay with cash-on-delivery option
- **Stock Management**: Automatic stock reduction after successful payment

### User Management
- **Authentication**: Email/password and Google Sign-In
- **Guest Mode**: Browse and shop without account (web)
- **Profile Management**: Update avatar, personal information
- **Address Management**: Multiple shipping addresses with Vietnam address picker
- **Order History**: View past orders with detailed tracking
- **Loyalty Points**: Earn and track loyalty points

### Additional Features
- **Voucher System**: Apply discount vouchers to orders
- **Rating & Reviews**: Rate and review purchased products
- **Survey System**: User preference surveys for better recommendations
- **Multi-language**: English and Vietnamese support
- **Dark Mode**: Light and dark theme support
- **Responsive Design**: Optimized for mobile, tablet, and desktop

## 🛠 Technology Stack

### Frontend
- **Flutter** 3.3.0+ (Dart SDK)
- **State Management**: 
  - BLoC/Cubit pattern (`flutter_bloc`)
  - Provider for theme and language
- **UI Components**: Material Design 3
- **Localization**: `flutter_localizations` + custom i18n
- **Image Handling**: `cached_network_image`, `image_picker`

### Backend & Services
- **Firebase**:
  - Authentication (Email/Password, Google Sign-In)
  - Firestore (Database)
  - Storage (Images, avatars)
  - App Check (Mobile security)
  - Cloud Functions (Serverless functions)
- **Google Gemini AI**: Chat assistant and NLP
- **Vertex AI**: Product recommendations and compatibility checking
- **Stripe**: Payment processing
- **SePay**: Vietnamese bank transfer payments

### Additional Packages
- **Dio**: HTTP client
- **PDF Generation**: `printing`, `pdf`
- **Speech to Text**: `speech_to_text`
- **Permissions**: `permission_handler`
- **Environment Variables**: `flutter_dotenv`
- **Persistence**: `shared_preferences`

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point, routing, theme configuration
├── app_view.dart                # App view wrapper
├── auth.dart                    # Authentication helper
├── firebase_options.dart        # Firebase configuration
│
├── components/                  # Reusable UI components
│   ├── chat/                   # Chat UI components
│   ├── general/                # General components (header, footer, sidebar)
│   └── home/                   # Home screen components
│
├── screens/                     # Application screens
│   ├── authentication/         # Sign in, sign up, password reset
│   ├── home/                   # Home screen with product showcases
│   ├── product/                # Product listing, detail, filtering
│   ├── cart/                   # Cart, checkout, payment
│   ├── user/                   # User profile, orders, addresses, vouchers
│   ├── builder/                # PC builder tool
│   ├── chat/                   # AI chat interface
│   └── starting/               # Loading and splash screens
│
├── services/                    # Business logic and API services
│   ├── ai_service.dart         # Main AI chat service
│   ├── ai_services/            # AI sub-services (NLP, product, cart, etc.)
│   ├── stripe_services.dart    # Stripe payment integration
│   ├── sepay_services.dart     # SePay payment integration
│   ├── recommendation_service.dart  # Product recommendations
│   ├── storage_service.dart    # Firebase Storage operations
│   └── web_guest_service.dart  # Guest user management (web)
│
├── data/                        # Data layer
│   ├── database/               # Local database and cache
│   └── firebase/               # Firebase operations
│
├── objects/                     # Data models
│   ├── product_related/        # Product models (CPU, GPU, RAM, etc.)
│   ├── invoice_related/        # Order and invoice models
│   ├── address_related/        # Address models
│   ├── voucher_related/        # Voucher models
│   └── chat_related/           # Chat message models
│
├── widgets/                     # Reusable widgets
│   ├── dialog/                 # Dialog widgets
│   ├── filter/                 # Filter widgets
│   ├── general/                # General widgets
│   ├── product/                # Product-specific widgets
│   └── voucher/                # Voucher widgets
│
├── enums/                       # Enumeration types
│   ├── product_related/        # Product enums (category, status, etc.)
│   ├── invoice_related/        # Invoice enums (payment method, status)
│   ├── processing/             # Processing enums (sort, state)
│   └── voucher_related/        # Voucher enums
│
├── providers/                   # State providers
│   ├── cart_provider.dart      # Shopping cart state
│   ├── theme_provider.dart     # Theme state
│   └── language_provider.dart  # Language state
│
├── functions/                   # Utility functions
│   ├── helper.dart             # General helper functions
│   ├── converter.dart          # Data converters
│   └── custom_exception.dart   # Custom exceptions
│
└── generated/                   # Generated code
    ├── l10n.dart               # Localization (English)
    └── l10n_vi.dart            # Localization (Vietnamese)
```

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK 3.3.0 or higher
- Dart SDK 3.3.0 or higher
- Firebase account and project
- Stripe account (for payment processing)
- SePay account (for Vietnamese bank transfers)
- Google Cloud account (for Gemini AI and Vertex AI)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd SE121.P11-GizmoGlobe-Client_side
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   Create a `.env` file in the root directory:
   ```env
   # Firebase (auto-configured via firebase_options.dart)
   
   # Stripe
   STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
   STRIPE_SECRET_KEY=your_stripe_secret_key
   
   # SePay (Vietnam bank transfers)
   SEPAY_API_TOKEN=your_sepay_api_token
   SEPAY_API_BASE_URL=https://my.sepay.vn/userapi
   
   # Google Gemini AI
   GEMINI_API_KEY=your_gemini_api_key
   
   # Vertex AI (optional, for advanced recommendations)
   VERTEX_AI_PROJECT_ID=your_project_id
   ```

4. **Firebase Setup**
   - Run `firebase init` in the project root
   - Ensure `firebase_options.dart` is properly configured
   - Set up Firestore database rules
   - Configure Firebase Storage rules
   - Enable Authentication providers (Email/Password, Google)

5. **Platform-specific setup**

   **Web:**
   - No additional setup required
   - Uses hash-based routing

   **Android:**
   - Ensure `google-services.json` is in `android/app/`
   - Configure app signing

   **iOS:**
   - Ensure `GoogleService-Info.plist` is in `ios/Runner/`
   - Configure app signing and capabilities

## ⚙️ Configuration

### Firebase Cloud Functions
The project uses Firebase Cloud Functions for:
- Stripe payment proxy (web CORS bypass)
- SePay API proxy (web CORS bypass)
- SePay webhook handler
- Gemini AI proxy (web)

Functions are located in `functions/` directory:
```bash
cd functions
npm install
firebase deploy --only functions
```

### Stripe Setup
1. Create a Stripe account
2. Get API keys from Stripe Dashboard
3. Add keys to `.env` file
4. Configure webhook endpoints (if needed)
5. Set up Cloud Function proxy for web

### SePay Setup
1. Register SePay account
2. Create API Token at: Cấu hình Công ty -> API Access
3. Add token to `.env` file
4. Configure webhook URL in SePay dashboard:
   ```
   https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayWebhook
   ```

### AI Configuration
1. **Gemini AI**: Get API key from Google AI Studio
2. **Vertex AI** (optional): Enable Vertex AI API in Google Cloud Console
3. Configure event tracking for product views (recommendations)

## 🏗 Architecture

### State Management
The app uses a hybrid approach:
- **BLoC/Cubit**: For complex business logic (products, cart, orders, chat)
- **Provider**: For app-wide state (theme, language, cart count)

### Data Flow
```
UI Layer (Screens/Widgets)
    ↓
BLoC/Cubit (Business Logic)
    ↓
Services (API calls, Firebase operations)
    ↓
Data Layer (Firebase, Local Storage)
```

### Key Patterns
- **Repository Pattern**: Firebase operations abstracted in `data/firebase/firebase.dart`
- **Factory Pattern**: Product creation via `ProductFactory`
- **Singleton Pattern**: Services like `Database`, `Firebase`, `StripeServices`
- **Observer Pattern**: Stream-based reactive updates

### Routing
- Hash-based routing for web (supports browser refresh)
- Named routes with dynamic route generation
- Deep linking support for product details, orders, etc.

## 📱 Key Features Details

### Product Management
- **Categories**: CPU, GPU, RAM, Storage (SSD/HDD), PSU, Mainboard
- **Filtering**: By category, manufacturer, price, specifications
- **Sorting**: Price, release date, sales, name
- **Search**: Full-text search with AI-powered understanding
- **Images**: Multiple product images with primary image selection
- **Stock Management**: Real-time stock tracking with automatic reduction on purchase

### Shopping Cart
- **Selection**: Multi-select items for checkout
- **Quantity Management**: Increase/decrease quantities
- **Subtotal Calculation**: Per-item and total calculations
- **Discount Application**: Voucher-based discounts
- **Stock Validation**: Real-time stock availability checking

### Checkout Process
1. **Address Selection**: Choose or add shipping address
2. **Voucher Application**: Apply available vouchers
3. **Payment Method Selection**: Stripe, SePay, or COD
4. **Invoice Creation**: Creates invoice in Firestore
5. **Payment Processing**: Handles payment based on method
6. **Stock Reduction**: Automatically reduces stock after payment confirmation
7. **Order Confirmation**: Shows success screen and updates order status

### AI Chat Assistant
Powered by Google Gemini AI with:
- **Question Classification**: Routes questions to appropriate handlers
- **Context Awareness**: Understands conversation history
- **Product Understanding**: NLP for product name recognition
- **Intent Detection**: Identifies user intent (search, compare, add to cart, etc.)
- **Multi-language**: Supports English and Vietnamese
- **Smart Responses**: Generates contextual, helpful responses

**Supported Commands:**
- Product search: "Show me RTX 4080"
- Add to cart: "Add Intel i7 to cart"
- Compare products: "Compare RTX 4080 vs RTX 4090"
- Price inquiries: "What's the price of RTX 4080?"
- Promotions: "What products are on sale?"
- Bestsellers: "Show me best selling GPUs"
- Compatibility: "Is RTX 4080 compatible with B550 mainboard?"

### PC Builder
- **5 Build Sessions**: Manage up to 5 different configurations
- **Component Selection**: Choose CPU, GPU, RAM, Storage, PSU, Mainboard
- **Compatibility Checking**: Validates component compatibility
- **Cost Calculation**: Real-time total cost
- **Save/Load**: Save configurations to Firestore
- **PDF Export**: Generate PDF configuration sheets
- **Buy Now**: Add entire configuration to cart

## 💳 Payment Integration

### Stripe
- **Web**: Stripe Checkout (redirect flow)
- **Mobile**: Stripe Payment Sheet (native UI)
- **Proxy**: Cloud Function proxy for web to bypass CORS

### SePay
- **Webhook-based**: Payment confirmation via webhook
- **Bank Transfer**: Direct bank transfer integration
- **Status Tracking**: Real-time payment status updates

### Payment Flow
1. User selects payment method at checkout
2. Invoice created in Firestore with `unpaid` status
3. Payment processed via selected method
4. On success:
   - Invoice updated to `paid` status
   - Stock automatically reduced
   - Order created with `pending` shipping status
5. On failure:
   - Invoice cancelled
   - Stock restored (if needed)

## 🤖 AI Chat Assistant

### Architecture
The AI service is modular with specialized handlers:

- **AIConversationService**: Manages conversation context
- **AIProductService**: Handles product-related queries
- **AICartService**: Manages cart operations
- **AIUserDataService**: Handles user data queries (favorites, orders)
- **AINLPService**: Natural language processing
- **AIQuestionClassifier**: Classifies user questions
- **CompatibilityHandler**: Component compatibility checking

### Features
- Context-aware conversations
- Product name recognition with synonyms
- Multi-intent handling
- Sentiment analysis for reviews
- Smart fallbacks when AI fails
- Rate limiting and error handling

## 📱 Platform Support

### Web
- Responsive design (mobile, tablet, desktop)
- Hash-based routing
- Guest user support (localStorage)
- Optimized performance
- PWA capabilities

### Mobile (Android/iOS)
- Native UI components
- Platform-specific features (camera, permissions)
- Offline support (local caching)
- Push notifications (future)

## 🏗 Build & Deploy

### Web Build
```bash
flutter build web
```
Output: `build/web/`

### Android Build
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS Build
```bash
flutter build ios --release
```

### Firebase Hosting (Web)
```bash
firebase deploy --only hosting
```

### Environment Variables
Ensure all required environment variables are set:
- `.env` file for local development
- Firebase Functions secrets for production
- Firebase App Check configuration

## 🔒 Security

- **Firebase App Check**: Mobile app verification
- **Firebase Security Rules**: Firestore and Storage rules
- **API Key Protection**: Keys stored in environment variables
- **Payment Security**: PCI-compliant payment processing via Stripe
- **Authentication**: Secure Firebase Authentication

## 📝 Localization

The app supports two languages:
- **English** (default)
- **Vietnamese**

Localization files:
- `lib/generated/l10n.dart` (English)
- `lib/generated/l10n_vi.dart` (Vietnamese)

All user-facing strings should use `S.of(context).stringKey` pattern.

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

## 📄 License

This project is private and not published to pub.dev.

## 👥 Development Team

SE121.P11 - GizmoGlobe Development Team

## 🔗 Related Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [Stripe Documentation](https://stripe.com/docs)
- [SePay Documentation](https://docs.sepay.vn/)
- [Google Gemini AI](https://ai.google.dev/)

## 📞 Support

For issues and questions, please contact the development team.

---

**Note**: This is a client-side application. Ensure the backend Firebase project is properly configured and all Cloud Functions are deployed before running the application.
