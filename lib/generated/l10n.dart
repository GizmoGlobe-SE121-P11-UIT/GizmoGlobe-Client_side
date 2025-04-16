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
