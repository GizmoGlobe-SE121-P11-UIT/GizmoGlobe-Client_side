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
  String get rate => Intl.message('Rate this order', name: 'rate');
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
  String get rememberYourPassword =>
      Intl.message('Remember your password? ', name: 'rememberYourPassword');
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
  String get orderStatus => Intl.message('Order Status', name: 'orderStatus');
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
  String get cashOnDelivery =>
      Intl.message('Cash on Delivery', name: 'cashOnDelivery');
  String get payWhenYouReceive =>
      Intl.message('Pay when you receive your order',
          name: 'payWhenYouReceive');
  String get sepay => Intl.message('SePay', name: 'sepay');
  String get sepayDescription => Intl.message(
        'Bank transfer (VietQR)',
        name: 'sepayDescription',
      );
  String get sepayScanInstructionsTitle => Intl.message(
        'Scan QR code to pay',
        name: 'sepayScanInstructionsTitle',
      );
  String get sepayScanInstructionsSubtitle => Intl.message(
        'Open your banking app and scan the QR code below to complete the payment.',
        name: 'sepayScanInstructionsSubtitle',
      );
  String get sepayPaymentDetailsTitle => Intl.message(
        'Payment Details',
        name: 'sepayPaymentDetailsTitle',
      );
  String get sepayAmountLabel =>
      Intl.message('Amount', name: 'sepayAmountLabel');
  String get sepayBankAccountLabel =>
      Intl.message('Bank Account', name: 'sepayBankAccountLabel');
  String get sepayBankLabel => Intl.message('Bank', name: 'sepayBankLabel');
  String get sepayOrderIdLabel =>
      Intl.message('Order ID', name: 'sepayOrderIdLabel');
  String get sepayWaitingForPayment => Intl.message(
        'Waiting for payment...',
        name: 'sepayWaitingForPayment',
      );
  String get sepayManualInstructionsTitle => Intl.message(
        'Manual Transfer Instructions',
        name: 'sepayManualInstructionsTitle',
      );
  String get sepayManualInstructions => Intl.message(
        '1. Open your banking app\n2. Select transfer/scan QR\n3. Scan the code or enter account details\n4. Enter the exact amount\n5. Complete the transfer',
        name: 'sepayManualInstructions',
      );
  String get sepayClose => Intl.message('Close', name: 'sepayClose');
  String get sepayRestoringCart =>
      Intl.message('Restoring cart...', name: 'sepayRestoringCart');
  String get sepayPaymentSuccessMessage => Intl.message(
        'Your payment has been confirmed successfully.',
        name: 'sepayPaymentSuccessMessage',
      );
  String get sepayPaymentInitFailed => Intl.message(
        'Failed to initialize payment',
        name: 'sepayPaymentInitFailed',
      );
  String get sepayGoBack => Intl.message('Go Back', name: 'sepayGoBack');
  String get stripe => Intl.message('Stripe', name: 'stripe');
  String get stripeDescription =>
      Intl.message('Credit/Debit card payment', name: 'stripeDescription');
  String get stripeMinimumOrder =>
      Intl.message('Minimum order: 15,000 VND', name: 'stripeMinimumOrder');
  String get transactionContentLabel =>
      Intl.message('Transfer content', name: 'transactionContentLabel');
  String get transactionContentCopied => Intl.message(
        'Transfer content copied to clipboard',
        name: 'transactionContentCopied',
      );
  String get copy => Intl.message('Copy', name: 'copy');
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
  String get addYourFirstAddress =>
      Intl.message('Add your first address to get started',
          name: 'addYourFirstAddress');
  String get edit => Intl.message('Edit', name: 'edit');
  String get delete => Intl.message('Delete', name: 'delete');
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
  String get recommendedForYou =>
      Intl.message('Recommended for You', name: 'recommendedForYou');
  String get seeAll => Intl.message('See All', name: 'seeAll');
  String get appLogo => Intl.message('App Logo', name: 'appLogo');
  String get chatButton => Intl.message('Chat Support', name: 'chatButton');
  String get helloGreeting => Intl.message('Hello,', name: 'helloGreeting');

  // Survey
  String get surveyJoin => Intl.message('Join the survey', name: 'surveyJoin');
  String get surveyTitle => Intl.message('Survey', name: 'surveyTitle');
  String get surveyBack => Intl.message('Back', name: 'surveyBack');
  String get surveyNext => Intl.message('Next', name: 'surveyNext');
  String get surveySubmit => Intl.message('Submit', name: 'surveySubmit');
  String get surveySubmitted =>
      Intl.message('Survey submitted', name: 'surveySubmitted');

  // Survey Questions
  String get surveyQAge =>
      Intl.message('What age group do you belong to?', name: 'surveyQAge');
  String get surveyQPurpose =>
      Intl.message('What do you mainly use your computer for?',
          name: 'surveyQPurpose');
  String get surveyQCurrentDevice =>
      Intl.message('What type of device are you currently using?',
          name: 'surveyQCurrentDevice');
  String get surveyQPreference =>
      Intl.message('When buying a new computer, what do you prefer?',
          name: 'surveyQPreference');
  String get surveyQKnowledge =>
      Intl.message('How well do you understand computer hardware?',
          name: 'surveyQKnowledge');
  String get surveyQBudget =>
      Intl.message('What is your budget for your next computer purchase?',
          name: 'surveyQBudget');
  String get surveyQDecisionFactor =>
      Intl.message('What is the most important factor when buying a computer?',
          name: 'surveyQDecisionFactor');
  String get surveyQPurchaseMethod =>
      Intl.message('How do you usually decide to buy a computer?',
          name: 'surveyQPurchaseMethod');

  // Survey Options - Age
  String get surveyOptUnder18 =>
      Intl.message('Under 18 years old', name: 'surveyOptUnder18');
  String get surveyOpt18_24 =>
      Intl.message('18 - 24 years old', name: 'surveyOpt18_24');
  String get surveyOpt25_34 =>
      Intl.message('25 - 34 years old', name: 'surveyOpt25_34');
  String get surveyOpt35_44 =>
      Intl.message('35 - 44 years old', name: 'surveyOpt35_44');
  String get surveyOpt45_54 =>
      Intl.message('45 - 54 years old', name: 'surveyOpt45_54');
  String get surveyOpt55Plus =>
      Intl.message('55 years old or above', name: 'surveyOpt55Plus');

  // Survey Options - Purpose
  String get surveyOptOffice =>
      Intl.message('Study / Office work', name: 'surveyOptOffice');
  String get surveyOptDesign =>
      Intl.message('Graphic design / Architecture / Multimedia',
          name: 'surveyOptDesign');
  String get surveyOptProgramming =>
      Intl.message('Programming / Engineering', name: 'surveyOptProgramming');
  String get surveyOptGaming => Intl.message('Gaming', name: 'surveyOptGaming');
  String get surveyOptEntertainment =>
      Intl.message('Entertainment (movies, music, web browsing)',
          name: 'surveyOptEntertainment');

  // Survey Options - Current Device
  String get surveyOptLaptop => Intl.message('Laptop', name: 'surveyOptLaptop');
  String get surveyOptPrebuiltPc =>
      Intl.message('Pre-built PC', name: 'surveyOptPrebuiltPc');
  String get surveyOptCustomPc =>
      Intl.message('Custom-built PC from components',
          name: 'surveyOptCustomPc');

  // Survey Options - Preference
  String get surveyOptPreferLaptop =>
      Intl.message('Laptop', name: 'surveyOptPreferLaptop');
  String get surveyOptPreferPrebuilt =>
      Intl.message('Pre-built PC', name: 'surveyOptPreferPrebuilt');
  String get surveyOptPreferCustom =>
      Intl.message('Custom-built PC from components',
          name: 'surveyOptPreferCustom');
  String get surveyOptPreferConsult =>
      Intl.message('Not sure / Need consultation',
          name: 'surveyOptPreferConsult');

  // Survey Options - Knowledge
  String get surveyOptNovice =>
      Intl.message('Not familiar, rely on recommendations',
          name: 'surveyOptNovice');
  String get surveyOptBasic =>
      Intl.message('Basic knowledge (know component names, not in-depth)',
          name: 'surveyOptBasic');
  String get surveyOptAdvanced =>
      Intl.message('Good understanding (can choose configurations myself)',
          name: 'surveyOptAdvanced');
  String get surveyOptExpert =>
      Intl.message('Expert (can build and optimize myself)',
          name: 'surveyOptExpert');

  // Survey Options - Budget
  String get surveyOptUnder10m =>
      Intl.message('Under 10 million VND', name: 'surveyOptUnder10m');
  String get surveyOpt10_20m =>
      Intl.message('10 - 20 million VND', name: 'surveyOpt10_20m');
  String get surveyOpt20_30m =>
      Intl.message('20 - 30 million VND', name: 'surveyOpt20_30m');
  String get surveyOpt30_50m =>
      Intl.message('30 - 50 million VND', name: 'surveyOpt30_50m');
  String get surveyOptOver50m =>
      Intl.message('Over 50 million VND', name: 'surveyOptOver50m');

  // Survey Options - Decision Factor
  String get surveyOptPerformance =>
      Intl.message('Performance (specifications)',
          name: 'surveyOptPerformance');
  String get surveyOptPrice => Intl.message('Price', name: 'surveyOptPrice');
  String get surveyOptBrand => Intl.message('Brand', name: 'surveyOptBrand');
  String get surveyOptDesignLook =>
      Intl.message('Design / Appearance', name: 'surveyOptDesignLook');
  String get surveyOptWarranty =>
      Intl.message('Warranty / Service', name: 'surveyOptWarranty');
  String get surveyOptOther => Intl.message('Other', name: 'surveyOptOther');

  // Survey Options - Purchase Method
  String get surveyOptOnlineSelf =>
      Intl.message('Buy online after researching myself',
          name: 'surveyOptOnlineSelf');
  String get surveyOptOnlineInfluencer =>
      Intl.message('Buy online based on reviewer/influencer recommendations',
          name: 'surveyOptOnlineInfluencer');
  String get surveyOptOfflineStore =>
      Intl.message('Buy at physical store', name: 'surveyOptOfflineStore');
  String get surveyOptFriendsAdvice =>
      Intl.message('Get advice from friends/family',
          name: 'surveyOptFriendsAdvice');

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
  String get psuEfficiency =>
      Intl.message('PSU Efficiency', name: 'psuEfficiency');
  String get psuModular => Intl.message('PSU Modular', name: 'psuModular');
  String get connectors => Intl.message('Connectors', name: 'connectors');
  String get series => Intl.message('Series', name: 'series');
  String get gpuVersion => Intl.message('GPU Version', name: 'gpuVersion');
  String get gpuMemory => Intl.message('GPU Memory', name: 'gpuMemory');
  String get gpuClockSpeed =>
      Intl.message('GPU Clock Speed', name: 'gpuClockSpeed');
  String get ioPorts => Intl.message('I/O Ports', name: 'ioPorts');
  String get driveGeneration =>
      Intl.message('Generation', name: 'driveGeneration');
  String get driveCapacity =>
      Intl.message('Drive Capacity', name: 'driveCapacity');
  String get driveInterface =>
      Intl.message('Interface', name: 'driveInterface');
  String get readSpeed => Intl.message('Read Speed', name: 'readSpeed');
  String get writeSpeed => Intl.message('Write Speed', name: 'writeSpeed');
  String get chipset => Intl.message('Chipset', name: 'chipset');
  String get ramSpec => Intl.message('RAM Spec', name: 'ramSpec');
  String get storageSlots =>
      Intl.message('Storage Slots', name: 'storageSlots');
  String get pcieSlots => Intl.message('PCIe Slots', name: 'pcieSlots');
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
  String get buyNow => Intl.message('Buy Now', name: 'buyNow');
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
  String get ramBus => Intl.message('RAM Bus', name: 'ramBus');
  String get clLatency => Intl.message('CL Latency', name: 'clLatency');
  String get kitStickCount =>
      Intl.message('Kit Stick Count', name: 'kitStickCount');
  String get ramCapacity => Intl.message('Capacity', name: 'ramCapacity');
  String get capacityPerStick =>
      Intl.message('Capacity Per Stick', name: 'capacityPerStick');
  String get gbEach => Intl.message('GB each', name: 'gbEach');
  String get gbInTotal => Intl.message('GB in total', name: 'gbInTotal');
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
  String get releaseLatest =>
      Intl.message('Release Latest', name: 'releaseLatest');
  String get releaseOldest =>
      Intl.message('Release Oldest', name: 'releaseOldest');
  String get salesHighest =>
      Intl.message('Sales Highest', name: 'salesHighest');
  String get salesLowest => Intl.message('Sales Lowest', name: 'salesLowest');
  String get priceHighest =>
      Intl.message('Price Highest', name: 'priceHighest');
  String get priceLowest => Intl.message('Price Lowest', name: 'priceLowest');

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
  String itemsCount(int count) => Intl.message(
        'Items ($count)',
        name: 'itemsCount',
        args: [count],
      );
  String get originalPrice =>
      Intl.message('Original Price', name: 'originalPrice');
  String get free => Intl.message('Free', name: 'free');
  String get clearCart => Intl.message('Clear Cart', name: 'clearCart');
  String get clearCartConfirmation => Intl.message(
        'Are you sure you want to clear all items from your cart?',
        name: 'clearCartConfirmation',
      );
  String get clearAll => Intl.message('Clear All', name: 'clearAll');
  String get voucherAppliedSuccessfully => Intl.message(
        'Voucher applied successfully',
        name: 'voucherAppliedSuccessfully',
      );
  String get shippingAddressUpdatedSuccessfully => Intl.message(
        'Shipping address updated successfully',
        name: 'shippingAddressUpdatedSuccessfully',
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
  String expiresIn(int days) =>
      Intl.message('Expires in $days days', name: 'expiresIn', args: [days]);
  String get maximumDiscount =>
      Intl.message('Maximum discount', name: 'maximumDiscount');
  String get voucherDetail =>
      Intl.message('Voucher Details', name: 'voucherDetail');
  String get maxUsagePerPerson =>
      Intl.message('Number of uses left', name: 'maxUsagePerPerson');
  String get description => Intl.message('Description', name: 'description');
  String get noEndTime => Intl.message('No end time', name: 'noEndTime');

  String get retry => Intl.message('Retry', name: 'retry');

  // Product mini card localization
  String get unableToNavigate => Intl.message(
        'Unable to navigate. Please try again.',
        name: 'unableToNavigate',
      );
  String get productInfoLoading => Intl.message(
        'Product information is loading. Please try again in a moment.',
        name: 'productInfoLoading',
      );
  String inStockItems(int count) => Intl.message(
        'In stock ($count items)',
        name: 'inStockItems',
        args: [count],
      );
  String get outOfStock => Intl.message('Out of stock', name: 'outOfStock');
  String get viewDetails => Intl.message('View details', name: 'viewDetails');

  // Hero Section
  String get limitedTimeOffer =>
      Intl.message('LIMITED TIME OFFER', name: 'limitedTimeOffer');
  String get buildYourDreamPc =>
      Intl.message('Build your PC', name: 'buildYourDreamPc');
  String get premiumComponentsForPc =>
      Intl.message('Premium components for your PC.',
          name: 'premiumComponentsForPc');
  String get shopNow => Intl.message('Shop Now', name: 'shopNow');
  String get freeShipping =>
      Intl.message('Free Shipping', name: 'freeShipping');
  String get support => Intl.message('Support', name: 'support');
  String get latestPcComponents =>
      Intl.message('Latest PC components', name: 'latestPcComponents');
  String get expertAssistance =>
      Intl.message('Expert assistance', name: 'expertAssistance');
  String get fastAndReliable =>
      Intl.message('Fast & reliable', name: 'fastAndReliable');
  String get shippingLabel => Intl.message('Shipping', name: 'shippingLabel');

  // Product Sections
  String get topRatedProductsLovedByCustomers =>
      Intl.message('Top-rated products loved by our customers',
          name: 'topRatedProductsLovedByCustomers');
  String get yourFavorites =>
      Intl.message('Your Favorites', name: 'yourFavorites');
  String get productsInYourWishlist =>
      Intl.message('Products in your wishlist', name: 'productsInYourWishlist');
  String get productRecommendationsForYourBuild =>
      Intl.message('Product recommendations for your build',
          name: 'productRecommendationsForYourBuild');

  // Guest restrictions
  String get loginRequired =>
      Intl.message('Login Required', name: 'loginRequired');
  String get loginRequiredForCart =>
      Intl.message('Please sign in to add items to cart',
          name: 'loginRequiredForCart');
  String get loginRequiredForFavorites =>
      Intl.message('Please sign in to add items to favorites',
          name: 'loginRequiredForFavorites');
  String get loginRequiredForChat =>
      Intl.message('Please sign in to access chat support',
          name: 'loginRequiredForChat');

  /// `Continue with Google`
  String get continueWithGoogle =>
      Intl.message('Continue with Google', name: 'continueWithGoogle');

  String get googleSignInCancelled =>
      Intl.message('Google sign-in was cancelled. You can try again anytime.',
          name: 'googleSignInCancelled');

  // Chat actions
  String get switchToAdmin =>
      Intl.message('Switch to Admin', name: 'switchToAdmin');
  String get switchToAI => Intl.message('Switch to AI', name: 'switchToAI');

  // Favorite operations
  String get addedToFavorites =>
      Intl.message('Added to favorites', name: 'addedToFavorites');
  String get removedFromFavorites =>
      Intl.message('Removed from favorites', name: 'removedFromFavorites');

  // Error messages
  String get failedToAddToCart =>
      Intl.message('Failed to add to cart', name: 'failedToAddToCart');
  String get failedToUpdateFavorites =>
      Intl.message('Failed to update favorites',
          name: 'failedToUpdateFavorites');

  // User menu
  String get accountInfo =>
      Intl.message('Account information', name: 'accountInfo');
  String get signOut => Intl.message('Sign Out', name: 'signOut');

  // User Profile Screen
  String get profilePicture =>
      Intl.message('Profile Picture', name: 'profilePicture');
  String get changeAvatar =>
      Intl.message('Change Avatar', name: 'changeAvatar');
  String get upload => Intl.message('Upload', name: 'upload');
  String get username => Intl.message('Username', name: 'username');
  String get emailCannotBeChanged =>
      Intl.message('Email cannot be changed', name: 'emailCannotBeChanged');
  String get sendPasswordResetEmail =>
      Intl.message('Send Password Reset Email', name: 'sendPasswordResetEmail');
  String get tapAvatarToChange =>
      Intl.message('Tap the avatar to change your profile picture',
          name: 'tapAvatarToChange');
  String get imageFormatHint =>
      Intl.message('JPG, PNG or GIF (Max 5MB)', name: 'imageFormatHint');

  // Order screen
  String get yourOrdersWillAppearHere =>
      Intl.message('Your orders will appear here',
          name: 'yourOrdersWillAppearHere');

  String get downloadInvoice =>
      Intl.message('Download invoice', name: 'downloadInvoice');

  String get cannotCancelTitle =>
      Intl.message('Cannot cancel', name: 'cannotCancelTitle');
  String get cannotCancelMessage =>
      Intl.message('This order can no longer be cancelled.',
          name: 'cannotCancelMessage');
  String get cancelSuccessTitle =>
      Intl.message('Order cancelled', name: 'cancelSuccessTitle');
  String get cancelSuccessMessage =>
      Intl.message('The order was cancelled successfully.',
          name: 'cancelSuccessMessage');
  String get cancelFailedTitle =>
      Intl.message('Cancel failed', name: 'cancelFailedTitle');
  String cancelFailedMessage(Object error) =>
      Intl.message('Unable to cancel this order.',
          name: 'cancelFailedMessage', args: [error]);

  String get cancelled => Intl.message('Cancelled', name: 'cancelled');

  String get noCancelledOrders =>
      Intl.message('You have no cancelled orders.', name: 'noCancelledOrders');

  // PC Builder
  String get enableCompatibilityChecker =>
      Intl.message('Enable compatibility checker',
          name: 'enableCompatibilityChecker');
  String get builderAddTooltip =>
      Intl.message('New session', name: 'builderAddTooltip');
  String get builderDeleteTooltip =>
      Intl.message('Delete session', name: 'builderDeleteTooltip');
  String get builderResetTooltip =>
      Intl.message('Reset session', name: 'builderResetTooltip');
  String get builderUploadTooltip =>
      Intl.message('Upload session', name: 'builderUploadTooltip');
  String get builderDownloadTooltip =>
      Intl.message('Load session', name: 'builderDownloadTooltip');
  String get builderResetTitle =>
      Intl.message('Reset builder?', name: 'builderResetTitle');
  String get builderResetMessage => Intl.message(
      'This will remove all components and quantities from the current session.',
      name: 'builderResetMessage');
  String get builderDeleteTitle =>
      Intl.message('Delete builder session?', name: 'builderDeleteTitle');
  String get builderDeleteMessage =>
      Intl.message('This action cannot be undone. Do you want to continue?',
          name: 'builderDeleteMessage');
  String get builderSessionsTitle =>
      Intl.message('Saved builder sessions', name: 'builderSessionsTitle');
  String get builderSessionsEmpty =>
      Intl.message('You do not have any saved builder sessions yet.',
          name: 'builderSessionsEmpty');
  String get builderSessionUpdatedLabel =>
      Intl.message('Updated', name: 'builderSessionUpdatedLabel');
  String builderSessionComponents(int count) => Intl.message(
        '$count components',
        name: 'builderSessionComponents',
        args: [count],
      );
  String get loading => Intl.message('Loading...', name: 'loading');

  // Ratings
  String get ratingsAndReviews =>
      Intl.message('Ratings & Reviews', name: 'ratingsAndReviews');
  String reviews(int count) => Intl.message(
        '$count reviews',
        name: 'reviews',
        args: [count],
      );
  String get noRatingsYet =>
      Intl.message('No ratings yet', name: 'noRatingsYet');
  String get showMore => Intl.message('Show more', name: 'showMore');

  // Order Rating
  String get rateProduct => Intl.message('Rate Product', name: 'rateProduct');
  String get commentOptional =>
      Intl.message('Comment (optional)', name: 'commentOptional');
  String get addImages => Intl.message('Add images', name: 'addImages');
  String get addVideo => Intl.message('Add video', name: 'addVideo');
  String get submitRating => Intl.message('Submit', name: 'submitRating');
  String get allReviews => Intl.message('All Reviews', name: 'allReviews');
  String get mostRecent => Intl.message('Most Recent', name: 'mostRecent');
  String get mostHelpful => Intl.message('Most Helpful', name: 'mostHelpful');
  String get highestRated =>
      Intl.message('Highest Rated', name: 'highestRated');
  String get lowestRated => Intl.message('Lowest Rated', name: 'lowestRated');

  // Sentiment Analysis
  String get checkContent =>
      Intl.message('Check Content', name: 'checkContent');
  String get submitRatingButton =>
      Intl.message('Submit Rating', name: 'submitRatingButton');
  String get analyzingSentiment =>
      Intl.message('Analyzing sentiment...', name: 'analyzingSentiment');
  String get sentimentPositive =>
      Intl.message('Positive', name: 'sentimentPositive');
  String get sentimentNegative =>
      Intl.message('Negative', name: 'sentimentNegative');
  String get sentimentNeutral =>
      Intl.message('Neutral', name: 'sentimentNeutral');
  String get sentimentMixed => Intl.message('Mixed', name: 'sentimentMixed');

  // Rating validation messages
  String get ratingRequired =>
      Intl.message('Rating Required', name: 'ratingRequired');
  String get pleaseProvideRating =>
      Intl.message('Please provide a rating.', name: 'pleaseProvideRating');
  String get fileSizeLimit =>
      Intl.message('File Size Limit', name: 'fileSizeLimit');
  String get totalSizeMustBe10MB =>
      Intl.message('Total size must be <= 10 MB.', name: 'totalSizeMustBe10MB');
  String get inappropriateContent =>
      Intl.message('Inappropriate Content', name: 'inappropriateContent');
  String get commentContainsInappropriateLanguage => Intl.message(
      'Your comment contains inappropriate language. Please revise and try again.',
      name: 'commentContainsInappropriateLanguage');
  String get ratingMismatch =>
      Intl.message('Rating Mismatch', name: 'ratingMismatch');
  String ratingMismatchMessage(String sentiment, int stars) => Intl.message(
        'Your comment seems $sentiment, but you gave $stars star${stars > 1 ? 's' : ''}. Please make sure your rating matches your experience.',
        name: 'ratingMismatchMessage',
        args: [sentiment, stars],
      );

  String get goodWithThisProduct =>
      Intl.message('Good with this product', name: 'goodWithThisProduct');

  // Footer
  String get footerTagline => Intl.message(
      'Your trusted source for premium PC components and peripherals.',
      name: 'footerTagline');
  String get onAllOrders => Intl.message('On all orders', name: 'onAllOrders');
  String get oneYearWarranty =>
      Intl.message('1-Year Warranty', name: 'oneYearWarranty');
  String get onAllProducts =>
      Intl.message('On all products', name: 'onAllProducts');
  String get support247 => Intl.message('24/7 Support', name: 'support247');
  String get securePayment =>
      Intl.message('Secure Payment', name: 'securePayment');
  String get sslEncrypted =>
      Intl.message('SSL encrypted', name: 'sslEncrypted');
  String get copyrightText =>
      Intl.message('© 2025 GizmoGlobe. All rights reserved.',
          name: 'copyrightText');
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
