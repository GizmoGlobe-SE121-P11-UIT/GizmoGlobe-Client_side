import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n_vi.dart';

class S {
  static S? _current;
  static S get current {
    _current ??= S();
    return _current!;
  }

  static S of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'vi') {
      return SVI();
    }
    return S();
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  String get appTitle => Intl.message('GizmoGlobe', name: 'appTitle');
  String get language => Intl.message('Language', name: 'language');
  String get languageEn => Intl.message('English', name: 'languageEn');
  String get languageVi => Intl.message('Vietnamese', name: 'languageVi');
  String get theme => Intl.message('Theme', name: 'theme');
  String get themeLight => Intl.message('Light', name: 'themeLight');
  String get themeDark => Intl.message('Dark', name: 'themeDark');
  String get themeSystem => Intl.message('System', name: 'themeSystem');
  String get settings => Intl.message('Settings', name: 'settings');
  String get accountSettings =>
      Intl.message('Account Settings', name: 'accountSettings');
  String get appSettings => Intl.message('App Settings', name: 'appSettings');
  String get editProfile => Intl.message('Edit Profile', name: 'editProfile');
  String get updatePersonalInfo =>
      Intl.message('Update your personal information',
          name: 'updatePersonalInfo');
  String get changeLanguage =>
      Intl.message('Change app language', name: 'changeLanguage');
  String get changeTheme =>
      Intl.message('Change app theme', name: 'changeTheme');
  String get guestAccount =>
      Intl.message('Guest Account', name: 'guestAccount');
  String get createAccount =>
      Intl.message('Create Account', name: 'createAccount');
  String get about => Intl.message('About', name: 'about');
  String get confirm => Intl.message('Confirm', name: 'confirm');
  String get cancel => Intl.message('Cancel', name: 'cancel');
  String get ok => Intl.message('OK', name: 'ok');
  String get from => Intl.message('From', name: 'from');
  String get min => Intl.message('Min', name: 'min');
  String get to => Intl.message('To', name: 'to');
  String get max => Intl.message('Max', name: 'max');
  String get success => Intl.message('Success', name: 'success');
  String get failure => Intl.message('Failure', name: 'failure');
  String get orderProcessing =>
      Intl.message('Your order is being processed.', name: 'orderProcessing');
  String get orderPreparing =>
      Intl.message('Your order is being prepared.', name: 'orderPreparing');
  String get orderShipping =>
      Intl.message('Your order is on the way.', name: 'orderShipping');
  String get orderDelivered =>
      Intl.message('Your order has been delivered.', name: 'orderDelivered');
  String get pleaseConfirmDelivery =>
      Intl.message('Please confirm the delivery.',
          name: 'pleaseConfirmDelivery');
  String get received => Intl.message('Received', name: 'received');
  String get orderCompleted =>
      Intl.message('Your order has been completed.', name: 'orderCompleted');
  String get thankYou =>
      Intl.message('Thank you for your purchase!', name: 'thankYou');
  String get statusUnknown =>
      Intl.message('Status: Unknown', name: 'statusUnknown');
  String get pleaseContactSupport =>
      Intl.message('Please contact support.', name: 'pleaseContactSupport');

  // Authentication
  String get login => Intl.message('Sign In', name: 'login');
  String get register => Intl.message('Sign Up', name: 'register');
  String get email => Intl.message('Email', name: 'email');
  String get password => Intl.message('Password', name: 'password');
  String get forgotPassword =>
      Intl.message('Forgot password?', name: 'forgotPassword');
  String get dontHaveAccount =>
      Intl.message("Don't have an account?", name: 'dontHaveAccount');
  String get or => Intl.message('or', name: 'or');
  String get continueAsGuest =>
      Intl.message('Continue as Guest', name: 'continueAsGuest');

  // Sign Up Screen
  String get fullName => Intl.message('Full name', name: 'fullName');
  String get phoneNumber => Intl.message('Phone number', name: 'phoneNumber');
  String get confirmPassword =>
      Intl.message('Confirm password', name: 'confirmPassword');
  String get alreadyHaveAccount =>
      Intl.message('Already have an account?', name: 'alreadyHaveAccount');
  String get enterFullName =>
      Intl.message('Enter your full name', name: 'enterFullName');
  String get enterPhoneNumber =>
      Intl.message('Enter your phone number', name: 'enterPhoneNumber');
  String get enterPassword =>
      Intl.message('Enter your password', name: 'enterPassword');
  String get enterConfirmPassword =>
      Intl.message('Confirm your password', name: 'enterConfirmPassword');

  // Error messages
  String get passwordTooShort =>
      Intl.message('The password provided is too weak.',
          name: 'passwordTooShort');
  String get emailAlreadyInUse =>
      Intl.message('An account already exists for that email.',
          name: 'emailAlreadyInUse');
  String get invalidEmail =>
      Intl.message('The email address is not valid.', name: 'invalidEmail');
  String get registerFailed =>
      Intl.message('Failed to sign up. Please try again.',
          name: 'registerFailed');

  // Cart Screen
  String get cart => Intl.message('Cart', name: 'cart');
  String get errorLoadingCart =>
      Intl.message('Error loading cart', name: 'errorLoadingCart');
  String get emptyCart => Intl.message('Your cart is empty', name: 'emptyCart');
  String get emptyCartDescription =>
      Intl.message('Add some products to your cart and they will show up here',
          name: 'emptyCartDescription');
  String get browseProducts =>
      Intl.message('Browse Products', name: 'browseProducts');
  String get removeItem => Intl.message('Remove Item', name: 'removeItem');
  String get removeItemConfirmation =>
      Intl.message('Are you sure you want to remove this item from your cart?',
          name: 'removeItemConfirmation');
  String get remove => Intl.message('Remove', name: 'remove');
  String get selectAll => Intl.message('Select all', name: 'selectAll');
  String get goToCheckout =>
      Intl.message('Go to checkout', name: 'goToCheckout');

  // Checkout Screen
  String get checkout => Intl.message('Checkout', name: 'checkout');
  String get checkoutTitle => Intl.message('Checkout', name: 'checkoutTitle');
  String get orderPlaced => Intl.message('Order Placed', name: 'orderPlaced');
  String get orderPlacedSuccess => Intl.message(
      'Your order has been placed successfully. You can track your order in the Orders section.',
      name: 'orderPlacedSuccess');
  String get viewOrder => Intl.message('View Order', name: 'viewOrder');
  String get paymentStatus =>
      Intl.message('Payment Status', name: 'paymentStatus');
  String get errorCheckout =>
      Intl.message('An error occurred during checkout', name: 'errorCheckout');
  String get paymentCancelled => Intl.message(
      'Payment was cancelled. Please try again or choose a different payment method.',
      name: 'paymentCancelled');
  String get tryAgain => Intl.message('Try Again', name: 'tryAgain');
  String get quantity => Intl.message('Quantity', name: 'quantity');
  String get shippingAddress =>
      Intl.message('Shipping Address', name: 'shippingAddress');
  String get chooseAddress =>
      Intl.message('Choose Address', name: 'chooseAddress');
  String get paymentMethod =>
      Intl.message('Payment Method', name: 'paymentMethod');
  String get orderSummary =>
      Intl.message('Order Summary', name: 'orderSummary');
  String get subtotal => Intl.message('Subtotal', name: 'subtotal');
  String get shippingFee => Intl.message('Shipping Fee', name: 'shippingFee');
  String get total => Intl.message('Total', name: 'total');
  String get placeOrder => Intl.message('Place Order', name: 'placeOrder');
  String get addShippingAddress =>
      Intl.message('Please choose an address', name: 'addShippingAddress');

  // Forget Password Screen
  String get forgetPassword =>
      Intl.message('Forget Password', name: 'forgetPassword');
  String get forgetPasswordDescription => Intl.message(
      'Do not worry! It happens. Please enter the email associated with your account.',
      name: 'forgetPasswordDescription');
  String get emailAddress =>
      Intl.message('Email address', name: 'emailAddress');
  String get enterYourEmail =>
      Intl.message('Enter your email address', name: 'enterYourEmail');
  String get sendVerificationLink =>
      Intl.message('Send Verification Link', name: 'sendVerificationLink');

  // Address Screen
  String get address => Intl.message('Address', name: 'address');
  String get noAddressFound =>
      Intl.message('No address found', name: 'noAddressFound');
  String get addAddress => Intl.message('Add Address', name: 'addAddress');
  String get editAddress => Intl.message('Edit Address', name: 'editAddress');
  String get deleteAddress =>
      Intl.message('Delete Address', name: 'deleteAddress');
  String get deleteAddressConfirmation =>
      Intl.message('Are you sure you want to delete this address?',
          name: 'deleteAddressConfirmation');
  String get receiverNameRequired =>
      Intl.message('Receiver name is required', name: 'receiverNameRequired');
  String get receiverPhoneRequired =>
      Intl.message('Receiver phone is required', name: 'receiverPhoneRequired');
  String get invalidPhoneNumber =>
      Intl.message('Invalid phone number', name: 'invalidPhoneNumber');
  String get addressSaved =>
      Intl.message('Address saved successfully', name: 'addressSaved');
  String get addressDeleted =>
      Intl.message('Address deleted successfully', name: 'addressDeleted');
  String get receiverName =>
      Intl.message('Receiver Name', name: 'receiverName');
  String get receiverPhone =>
      Intl.message('Receiver Phone', name: 'receiverPhone');
  String get streetAddress =>
      Intl.message('Street name, building, house no.', name: 'streetAddress');
  String get save => Intl.message('Save', name: 'save');

  // Chat Screen
  String get chatSupport => Intl.message('Chat Support', name: 'chatSupport');
  String get aiAssistant => Intl.message('AI Assistant', name: 'aiAssistant');
  String get adminSupport =>
      Intl.message('Admin Support', name: 'adminSupport');
  String get typeMessage =>
      Intl.message('Type a message...', name: 'typeMessage');
  String get send => Intl.message('Send', name: 'send');

  // Home Screen
  String get bestSellers => Intl.message('Best Sellers', name: 'bestSellers');
  String get favorites => Intl.message('Favorites', name: 'favorites');
  String get seeAll => Intl.message('See All', name: 'seeAll');
  String get appLogo => Intl.message('App Logo', name: 'appLogo');
  String get chatButton => Intl.message('Chat Support', name: 'chatButton');

  // Main Screen
  String get homeTab => Intl.message('Home', name: 'homeTab');
  String get productsTab => Intl.message('Products', name: 'productsTab');
  String get cartTab => Intl.message('Cart', name: 'cartTab');
  String get userTab => Intl.message('User', name: 'userTab');

  // Filter Screen
  String get filter => Intl.message('Filter', name: 'filter');
  String get price => Intl.message('Price', name: 'price');
  String get category => Intl.message('Category', name: 'category');
  String get bus => Intl.message('Bus', name: 'bus');
  String get capacity => Intl.message('Capacity', name: 'capacity');
  String get type => Intl.message('Type', name: 'type');
  String get family => Intl.message('Family', name: 'family');
  String get cpuCore => Intl.message('CPU Core', name: 'cpuCore');
  String get cpuThread => Intl.message('CPU Thread', name: 'cpuThread');
  String get cpuClockSpeed =>
      Intl.message('CPU Clock Speed', name: 'cpuClockSpeed');
  String get modular => Intl.message('Modular', name: 'modular');
  String get efficiency => Intl.message('Efficiency', name: 'efficiency');
  String get psuWattage => Intl.message('PSU Wattage', name: 'psuWattage');
  String get series => Intl.message('Series', name: 'series');
  String get gpuClockSpeed =>
      Intl.message('GPU Clock Speed', name: 'gpuClockSpeed');
  String get formFactor => Intl.message('Form Factor', name: 'formFactor');
  String get compatibility =>
      Intl.message('Compatibility', name: 'compatibility');
  String get manufacturer => Intl.message('Manufacturer', name: 'manufacturer');
  String get enterMinPrice =>
      Intl.message('Enter minimum price', name: 'enterMinPrice');
  String get enterMaxPrice =>
      Intl.message('Enter maximum price', name: 'enterMaxPrice');

  // Option Filter Strings
  String get fullModular => Intl.message('Full Modular', name: 'fullModular');
  String get semiModular => Intl.message('Semi Modular', name: 'semiModular');
  String get nonModular => Intl.message('Non Modular', name: 'nonModular');
  String get ddr3 => Intl.message('DDR3', name: 'ddr3');
  String get ddr4 => Intl.message('DDR4', name: 'ddr4');
  String get ddr5 => Intl.message('DDR5', name: 'ddr5');
  String get hdd => Intl.message('HDD', name: 'hdd');
  String get ssd => Intl.message('SSD', name: 'ssd');
  String get nvme => Intl.message('NVMe', name: 'nvme');
  String get atx => Intl.message('ATX', name: 'atx');
  String get microAtx => Intl.message('Micro ATX', name: 'microAtx');
  String get miniItx => Intl.message('Mini ITX', name: 'miniItx');
  String get eAtx => Intl.message('E-ATX', name: 'eAtx');

  // Product Detail Screen
  String get basicInformation =>
      Intl.message('Basic Information', name: 'basicInformation');
  String get product => Intl.message('Product', name: 'product');
  String get statusInformation =>
      Intl.message('Status Information', name: 'statusInformation');
  String get stock => Intl.message('Stock', name: 'stock');
  String get releaseDate => Intl.message('Release Date', name: 'releaseDate');
  String get technicalSpecifications =>
      Intl.message('Technical Specifications', name: 'technicalSpecifications');
  String get share => Intl.message('Share', name: 'share');
  String get addToWishlist =>
      Intl.message('Add to Wishlist', name: 'addToWishlist');
  String get totalPrice => Intl.message('Total Price', name: 'totalPrice');
  String get addToCart => Intl.message('Add to Cart', name: 'addToCart');
  String get productSpecifications =>
      Intl.message('Product Specifications', name: 'productSpecifications');
  String get memorySpecifications =>
      Intl.message('Memory Specifications', name: 'memorySpecifications');
  String get processorSpecifications =>
      Intl.message('Processor Specifications', name: 'processorSpecifications');
  String get powerSupplySpecifications =>
      Intl.message('Power Supply Specifications',
          name: 'powerSupplySpecifications');
  String get graphicsCardSpecifications =>
      Intl.message('Graphics Card Specifications',
          name: 'graphicsCardSpecifications');
  String get motherboardSpecifications =>
      Intl.message('Motherboard Specifications',
          name: 'motherboardSpecifications');
  String get storageSpecifications =>
      Intl.message('Storage Specifications', name: 'storageSpecifications');
  String get busSpeed => Intl.message('Bus Speed', name: 'busSpeed');
  String get ramType => Intl.message('RAM Type', name: 'ramType');
  String get cores => Intl.message('Cores', name: 'cores');
  String get threads => Intl.message('Threads', name: 'threads');
  String get clockSpeed => Intl.message('Clock Speed', name: 'clockSpeed');
  String get wattage => Intl.message('Wattage', name: 'wattage');
  String get memory => Intl.message('Memory', name: 'memory');
  String get busWidth => Intl.message('Bus Width', name: 'busWidth');
  String get driveType => Intl.message('Drive Type', name: 'driveType');

  // Product Screen
  String get findYourItem =>
      Intl.message('Find your item', name: 'findYourItem');
  String get all => Intl.message('All', name: 'all');
  String get ram => Intl.message('RAM', name: 'ram');
  String get cpu => Intl.message('CPU', name: 'cpu');
  String get psu => Intl.message('PSU', name: 'psu');
  String get gpu => Intl.message('GPU', name: 'gpu');
  String get drive => Intl.message('Drive', name: 'drive');
  String get mainboard => Intl.message('Mainboard', name: 'mainboard');

  // Product Tab Strings
  String get sortBy => Intl.message('Sort by:', name: 'sortBy');
  String get noProductsFound =>
      Intl.message('No products found', name: 'noProductsFound');
  String get priceAscending =>
      Intl.message('Price: Low to High', name: 'priceAscending');
  String get priceDescending =>
      Intl.message('Price: High to Low', name: 'priceDescending');
  String get nameAscending =>
      Intl.message('Name: A to Z', name: 'nameAscending');
  String get nameDescending =>
      Intl.message('Name: Z to A', name: 'nameDescending');
  String get newest => Intl.message('Newest', name: 'newest');
  String get oldest => Intl.message('Oldest', name: 'oldest');
  String get discountHighest =>
      Intl.message('Discount: Highest', name: 'discountHighest');
  String get discountLowest =>
      Intl.message('Discount: Lowest', name: 'discountLowest');

  // Address picker fields
  String get chooseProvince =>
      Intl.message('Choose Province', name: 'chooseProvince');
  String get chooseDistrict =>
      Intl.message('Choose District', name: 'chooseDistrict');
  String get chooseWard => Intl.message('Choose Ward', name: 'chooseWard');

  // New added getters
  String get orders => Intl.message('Orders', name: 'orders');
  String get orderConfirmed =>
      Intl.message('Confirmed', name: 'orderConfirmed');
  String get deliveryConfirmed =>
      Intl.message('The delivery has been confirmed.',
          name: 'deliveryConfirmed');
  String get noOrdersToShip =>
      Intl.message('No order is waiting to be shipped.',
          name: 'noOrdersToShip');
  String get noOrdersToReceive =>
      Intl.message('No order is waiting to be received.',
          name: 'noOrdersToReceive');
  String get noCompletedOrders =>
      Intl.message('No order has been completed.', name: 'noCompletedOrders');

  String get toShip => Intl.message('To Ship', name: 'toShip');
  String get toReceive => Intl.message('To Receive', name: 'toReceive');
  String get completed => Intl.message('Completed', name: 'completed');

  String totalItems(int count, String total) => Intl.message(
        'Total $count items: $total',
        name: 'totalItems',
        args: [count, total],
      );

  String get orderProcessingStatus => Intl.message(
        'Your order is being processed.',
        name: 'orderProcessingStatus',
      );

  String get myAddresses => Intl.message('My Addresses', name: 'myAddresses');
  String get manageDeliveryAddresses =>
      Intl.message('Manage your delivery addresses',
          name: 'manageDeliveryAddresses');
  String get changePassword =>
      Intl.message('Change Password', name: 'changePassword');
  String get resetPassword =>
      Intl.message('Reset Password', name: 'resetPassword');
  String get sendResetLink =>
      Intl.message('Send Reset Link', name: 'sendResetLink');
  String get updateAccountSecurity =>
      Intl.message('Update your account security',
          name: 'updateAccountSecurity');
  String get passwordResetEmailSent =>
      Intl.message('Password Reset Email Sent', name: 'passwordResetEmailSent');
  String passwordResetEmailContent(String email) => Intl.message(
        'A password reset link has been sent to $email. Please check your email to reset your password.',
        name: 'passwordResetEmailContent',
        args: [email],
      );
  String get themeSettings =>
      Intl.message('Theme Settings', name: 'themeSettings');
  String get developers => Intl.message('Developers', name: 'developers');
  String get termsAndConditions =>
      Intl.message('Terms & Conditions', name: 'termsAndConditions');
  String get privacyPolicy =>
      Intl.message('Privacy Policy', name: 'privacyPolicy');
  String get acceptanceOfTerms =>
      Intl.message('1. Acceptance of Terms', name: 'acceptanceOfTerms');
  String get useLicense => Intl.message('2. Use License', name: 'useLicense');
  String get disclaimer => Intl.message('3. Disclaimer', name: 'disclaimer');
  String get limitations => Intl.message('4. Limitations', name: 'limitations');
  String get informationWeCollect =>
      Intl.message('1. Information We Collect', name: 'informationWeCollect');
  String get howWeUseYourInformation =>
      Intl.message('2. How We Use Your Information',
          name: 'howWeUseYourInformation');
  String get informationSharing =>
      Intl.message('3. Information Sharing', name: 'informationSharing');
  String get dataSecurity =>
      Intl.message('4. Data Security', name: 'dataSecurity');

  // My Orders section
  String get myOrders => Intl.message('My Orders', name: 'myOrders');
  String get ordersToShip =>
      Intl.message('Orders to Ship', name: 'ordersToShip');
  String get ordersToReceive =>
      Intl.message('Orders to Receive', name: 'ordersToReceive');
  String get ordersCompleted =>
      Intl.message('Orders Completed', name: 'ordersCompleted');

  // App Settings section
  String get appSettingsTitle =>
      Intl.message('App Settings', name: 'appSettingsTitle');
  String get languageSettingsTitle =>
      Intl.message('Language Settings', name: 'languageSettingsTitle');
  String get themeSettingsTitle =>
      Intl.message('Theme Settings', name: 'themeSettingsTitle');

  // Account Settings section
  String get accountSettingsTitle =>
      Intl.message('Account Settings', name: 'accountSettingsTitle');
  String get editProfileSettings =>
      Intl.message('Edit Profile', name: 'editProfileSettings');
  String get myAddressesSettings =>
      Intl.message('My Addresses', name: 'myAddressesSettings');
  String get changePasswordSettings =>
      Intl.message('Change Password', name: 'changePasswordSettings');

  // About section
  String get aboutTitle => Intl.message('About', name: 'aboutTitle');
  String get versionInfo => Intl.message('Version', name: 'versionInfo');
  String get developersInfo =>
      Intl.message('Developers', name: 'developersInfo');
  String get termsAndConditionsDescription =>
      Intl.message('Read our terms and conditions',
          name: 'termsAndConditionsDescription');
  String get privacyPolicyDescription =>
      Intl.message('Read our privacy policy', name: 'privacyPolicyDescription');

  // Descriptions
  String get updateProfileDesc =>
      Intl.message('Update your personal information',
          name: 'updateProfileDesc');
  String get manageAddressesDesc =>
      Intl.message('Manage your delivery addresses',
          name: 'manageAddressesDesc');
  String get updateSecurityDescription =>
      Intl.message('Update your account security',
          name: 'updateSecurityDescription');
  String get changeLanguageDescription =>
      Intl.message('Change app language', name: 'changeLanguageDescription');
  String get changeThemeDescription =>
      Intl.message('Change app theme', name: 'changeThemeDescription');
  String get meetTeamDescription =>
      Intl.message('Meet our development team', name: 'meetTeamDescription');
  String get readTermsDesc =>
      Intl.message('Read our terms and conditions', name: 'readTermsDesc');
  String get readPrivacyDesc =>
      Intl.message('Read our privacy policy', name: 'readPrivacyDesc');

  // Logout
  String get logOut => Intl.message('Log Out', name: 'logOut');

  String get lightMode => Intl.message('Light Mode', name: 'lightMode');
  String get darkMode => Intl.message('Dark Mode', name: 'darkMode');
  String get meetDevelopmentTeam =>
      Intl.message('Meet Development Team', name: 'meetDevelopmentTeam');
  String get signUpWithEmail =>
      Intl.message('Sign Up with Email', name: 'signUpWithEmail');
  String get createAccountUsingEmail =>
      Intl.message('Create account using email',
          name: 'createAccountUsingEmail');
  String get alreadyHaveAccountQuestion =>
      Intl.message('Already have an account?',
          name: 'alreadyHaveAccountQuestion');
  String get enterNewUsername =>
      Intl.message('Enter new username', name: 'enterNewUsername');
  String get developer => Intl.message('Developer', name: 'developer');
  String get developerRole => Intl.message('Developer', name: 'developerRole');
  String get termsAndConditionsContent => Intl.message(
      'By accessing and using GizmoGlobe, you accept and agree to be bound by the terms and provision of this agreement.',
      name: 'termsAndConditionsContent');
  String get useLicenseContent => Intl.message(
      'Permission is granted to temporarily download one copy of the materials (information or software) on GizmoGlobe for personal, non-commercial transitory viewing only.',
      name: 'useLicenseContent');
  String get disclaimerContent => Intl.message(
      'The materials on GizmoGlobe are provided on an \'as is\' basis. GizmoGlobe makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
      name: 'disclaimerContent');
  String get limitationsContent => Intl.message(
      'In no event shall GizmoGlobe or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on GizmoGlobe.',
      name: 'limitationsContent');
  String get informationWeCollectContent => Intl.message(
      'We collect information that you provide directly to us, including when you create an account, make a purchase, or contact us for support.',
      name: 'informationWeCollectContent');
  String get howWeUseYourInformationContent => Intl.message(
      'We use the information we collect to provide, maintain, and improve our services, process your transactions, and communicate with you.',
      name: 'howWeUseYourInformationContent');
  String get informationSharingContent => Intl.message(
      'We do not sell or share your personal information with third parties except as described in this policy or with your consent.',
      name: 'informationSharingContent');
  String get dataSecurityContent => Intl.message(
      'We take reasonable measures to help protect your personal information from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
      name: 'dataSecurityContent');
  String get error => Intl.message('Error', name: 'error');
  String get failedToSigninAsGuest =>
      Intl.message('Failed to sign in as guest', name: 'failedToSigninAsGuest');
  String get totalCost => Intl.message('Total Cost', name: 'totalCost');
  String get aiWelcomeMessage =>
      Intl.message('Hello! I am your AI assistant. How can I help you today?',
          name: 'aiWelcomeMessage');
  String get adminWelcomeMessage => Intl.message(
      'Hello! This is admin contact channel. How can I assist you today?',
      name: 'adminWelcomeMessage');
  String get firstAdminResponse =>
      Intl.message('Admin will reply to your message soon.',
          name: 'firstAdminResponse');
  String get editProfileDescription =>
      Intl.message('Update your personal information',
          name: 'editProfileDescription');
  String get manageAddressDescription =>
      Intl.message('Manage your delivery addresses',
          name: 'customizeAddressDescription');
  String get changePasswordDescription =>
      Intl.message('Update your account security',
          name: 'changePasswordDescription');
  String get search => Intl.message('Search', name: 'search');
  String get signIn => Intl.message('Sign In', name: 'signIn');
  String get chooseMonthandYear => Intl.message(
        'Choose Month and Year',
        name: 'chooseMonthandYear',
      );
  String get pickAvatar => Intl.message(
        'Pick Avatar',
        name: 'pickAvatar',
      );
  String get chooseFromGallery => Intl.message(
        'Choose from Gallery',
        name: 'chooseFromGallery',
      );
  String get takeAPicture => Intl.message(
        'Take a Picture',
        name: 'takeAPicture',
      );
  String get chooseVoucher => Intl.message(
        'Choose Voucher',
        name: 'chooseVoucher',
      );
  String get noVouchersAvailable =>
      Intl.message('No vouchers available', name: 'noVouchersAvailable');

  String get voucher => Intl.message('Vouchers', name: 'voucher');
  String get addVoucher => Intl.message('Add Voucher', name: 'addVoucher');
  String get minimumPurchaseAmount =>
      Intl.message('Minimum purchase amount', name: 'minimumPurchaseAmount');
  String get ongoing => Intl.message('Ongoing', name: 'ongoing');
  String get upcoming => Intl.message('Upcoming', name: 'upcoming');
  String get startTime => Intl.message('Start time', name: 'startTime');
  String get endTime => Intl.message('End time', name: 'endTime');
  String get usage => Intl.message('Usage', name: 'usage');
  String get minimumPurchase =>
      Intl.message('Minimum purchase', name: 'minimumPurchase');
  String get discount => Intl.message('Discount', name: 'discount');
  String get myVouchers => Intl.message('My Vouchers', name: 'MyVouchers');
  String get disabled => Intl.message('Disabled', name: 'disabled');
  String get ranOut => Intl.message('Ran out', name: 'ranOut');
  String get expired => Intl.message('Expired', name: 'expired');
  String get available => Intl.message('Available', name: 'available');
  String get noExpiry => Intl.message('No expiry', name: 'noExpiry');
  String expiresIn(int days) => Intl.message('Expires in $days days', name: 'expiresIn', args: [days]);
  String get maximumDiscount => Intl.message('Maximum discount', name: 'maximumDiscount');
  String get voucherDetail => Intl.message('Voucher Details', name: 'voucherDetail');
  String get maxUsagePerPerson => Intl.message('Max. usage per person', name: 'maxUsagePerPerson');
  String get description => Intl.message('Description', name: 'description');
  String get noEndTime => Intl.message('No end time', name: 'noEndTime');
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'vi'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) {
    if (locale.languageCode == 'vi') {
      return Future.value(SVI());
    }
    return Future.value(S());
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}
