const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * SePay Webhook Handler
 * 
 * This function receives webhook notifications from SePay when a payment is received.
 * It updates the invoice in Firestore to mark it as paid.
 * 
 * Webhook URL: https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayWebhook
 * 
 * @see https://docs.sepay.vn/lap-trinh-webhooks.html
 */
exports.sepayWebhook = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Handle GET requests (for testing/browser access)
  if (req.method === 'GET') {
    return res.status(200).json({
      success: true,
      message: 'SePay Webhook endpoint is active and ready to receive webhooks',
      endpoint: 'sepayWebhook',
      method: 'POST',
      testEndpoint: 'https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayWebhookTest',
      note: 'This endpoint only accepts POST requests from SePay. Use the test endpoint for GET requests.',
      timestamp: new Date().toISOString(),
    });
  }

  // Only accept POST requests for actual webhooks
  if (req.method !== 'POST') {
    return res.status(405).json({ 
      success: false, 
      error: 'Method not allowed. Only POST requests are accepted.',
      allowedMethods: ['POST', 'GET'],
      note: 'GET requests return endpoint info. POST requests process webhooks.',
    });
  }

  try {
    console.log('SePay webhook received:', JSON.stringify(req.body, null, 2));

    // Parse webhook data from SePay
    const webhookData = req.body;
    
    // Extract and normalize fields
    const transferType = webhookData.transferType; // "in" for payment received, "out" for payment sent
    const transferAmount = parseFloat(webhookData.transferAmount || 0);
    const transactionDate = webhookData.transactionDate || webhookData.transferDate;
    const accountNumber = webhookData.accountNumber;
    const subAccount = webhookData.subAccount;
    const code = webhookData.code;
    const content = webhookData.content || webhookData.transactionContent;
    const description = webhookData.description;
    const accumulated = parseFloat(webhookData.accumulated || 0);
    const gateway = webhookData.gateway;
    const sepayId = webhookData.id;

    // Deduplication: avoid processing the same webhook multiple times
    // Determine invoice ID:
    // - Prefer webhookData.code if your SePay "Cấu trúc mã thanh toán" extracts it
    // - Fallback: parse "Order {invoiceId}" pattern from content/description
    let referenceNumber = null;
    if (code && String(code).trim().length > 0) {
      referenceNumber = String(code).trim();
    } else {
      const text = `${content || ''} ${description || ''}`;
      // Match patterns like "Order ABC123", "order 12345", "ORDER-XYZ"
      const orderMatch = text.match(/order[\s:-]*([A-Za-z0-9_-]{6,})/i);
      if (orderMatch && orderMatch[1]) {
        referenceNumber = orderMatch[1];
      }
    }

    if (!referenceNumber) {
      console.error('Unable to determine invoice ID (code/content missing or unparsable)');
      return res.status(400).json({ 
        success: false, 
        error: 'Missing invoice reference (code/content)' 
      });
    }

    console.log(`Processing webhook for invoice: ${referenceNumber}, type: ${transferType}, amount: ${transferAmount}`);

    // Only process incoming payments (transferType === "in")
    if (transferType !== "in") {
      console.log(`Ignoring outgoing transaction for invoice: ${referenceNumber}`);
      return res.status(200).json({ 
        success: true, 
        message: 'Ignored outgoing transaction' 
      });
    }

    // Find invoice by reference number (order ID)
    // The invoice ID should match the referenceCode
    const invoiceRef = admin.firestore()
      .collection('sales_invoices')
      .doc(referenceNumber);

    const invoiceDoc = await invoiceRef.get();

    if (!invoiceDoc.exists) {
      console.error(`Invoice not found: ${referenceNumber}`);
      return res.status(404).json({ 
        success: false, 
        error: `Invoice not found: ${referenceNumber}` 
      });
    }

    const invoiceData = invoiceDoc.data();

    // Check if invoice is already paid
    if (invoiceData.paymentStatus === 'paid') {
      console.log(`Invoice ${referenceNumber} is already paid, skipping update`);
      return res.status(200).json({ 
        success: true, 
        message: 'Invoice already paid' 
      });
    }

    // Verify payment amount matches invoice total (DB stores thousands → convert to VND)
    const invoiceAmount = (Number(invoiceData.totalPrice || 0)) * 1000;
    const paymentAmount = transferAmount;

    console.log(`Comparing amounts - Invoice: ${invoiceAmount} VND, Payment: ${paymentAmount} VND`);

    // Allow small tolerance for rounding (e.g., 100 VND)
    const tolerance = 100;
    if (Math.abs(paymentAmount - invoiceAmount) > tolerance) {
      console.error(`Payment amount mismatch: expected ${invoiceAmount}, received ${paymentAmount}`);
      return res.status(400).json({ 
        success: false, 
        error: `Payment amount mismatch: expected ${invoiceAmount} VND, received ${paymentAmount} VND` 
      });
    }

    // Update invoice payment status to paid
    // Use existing invoice 'date' as the paymentDate as requested
    const updateData = {
      paymentStatus: 'paid',
      paymentMethod: 'sepay',
      // Do not persist SePay-specific transient fields or separate paymentDate
      // The invoice 'date' field is considered the canonical time
    };

    await invoiceRef.update(updateData);

    console.log(`Successfully updated invoice ${referenceNumber} to paid status`);

    // Mark this webhook as processed for idempotency
    // Return success response to SePay
    return res.status(200).json({ 
      success: true,
      message: 'Payment processed successfully',
      invoiceId: referenceNumber,
    });

  } catch (error) {
    console.error('Error processing SePay webhook:', error);
    console.error('Error stack:', error.stack);

    return res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

/**
 * Test endpoint to verify webhook is working
 * 
 * URL: https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayWebhookTest
 */
exports.sepayWebhookTest = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  
  return res.status(200).json({
    success: true,
    message: 'SePay webhook endpoint is working',
    timestamp: new Date().toISOString(),
    projectId: 'se121p11-gizmoglobe',
  });
});

/**
 * SePay API Proxy
 * 
 * This function acts as a proxy for SePay API calls from the client.
 * It solves CORS issues by making API calls from the server-side.
 * 
 * URL: https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayApiProxy
 * 
 * Usage:
 * POST /sepayApiProxy
 * Body: {
 *   "endpoint": "bank-accounts", // API endpoint (without base URL)
 *   "method": "GET", // HTTP method
 *   "data": {} // Request data (for POST/PUT)
 * }
 */
exports.sepayApiProxy = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Handle GET requests (for testing)
  if (req.method === 'GET') {
    return res.status(200).json({
      success: true,
      message: 'SePay API Proxy is active',
      endpoint: 'sepayApiProxy',
      usage: 'POST requests with endpoint, method, and data',
      timestamp: new Date().toISOString(),
    });
  }

  try {
    // Get SePay API token from environment config
    // Priority: 1. Firebase config, 2. Environment variable
    let apiToken = functions.config().sepay?.api_token;
    if (!apiToken) {
      apiToken = process.env.SEPAY_API_TOKEN;
    }
    
    if (!apiToken) {
      console.error('SePay API token not configured');
      return res.status(500).json({
        success: false,
        error: 'SePay API token not configured. Set it using: firebase functions:config:set sepay.api_token="YOUR_TOKEN"',
        note: 'Or set SEPAY_API_TOKEN environment variable in Firebase Console',
      });
    }

    const baseUrl = 'https://my.sepay.vn/userapi';
    const endpoint = req.body.endpoint;
    const method = req.body.method || 'GET';
    const data = req.body.data || {};

    if (!endpoint) {
      return res.status(400).json({
        success: false,
        error: 'Missing endpoint in request body',
      });
    }

    console.log(`SePay API Proxy: ${method} ${baseUrl}/${endpoint}`);

    // Use Node.js https module to make request to SePay API
    const https = require('https');
    const url = require('url');

    const sepayUrl = new URL(`${baseUrl}/${endpoint}`);
    
    // Add query parameters for GET requests
    if (method === 'GET' && Object.keys(data).length > 0) {
      Object.keys(data).forEach(key => {
        sepayUrl.searchParams.append(key, data[key]);
      });
    }

    const options = {
      hostname: sepayUrl.hostname,
      port: 443,
      path: sepayUrl.pathname + sepayUrl.search,
      method: method,
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        'Content-Type': 'application/json',
      },
    };

    // Make request to SePay API
    return new Promise((resolve, reject) => {
      const reqSePay = https.request(options, (resSePay) => {
        let responseData = '';

        resSePay.on('data', (chunk) => {
          responseData += chunk;
        });

        resSePay.on('end', () => {
          try {
            // Log response for debugging
            console.log(`SePay API Response: ${resSePay.statusCode}`, responseData.substring(0, 500));
            
            // If status code is error, include error details
            if (resSePay.statusCode >= 400) {
              return res.status(200).json({
                success: false,
                error: `SePay API returned ${resSePay.statusCode}`,
                data: responseData || '',
                statusCode: resSePay.statusCode,
                endpoint: endpoint,
                url: `${baseUrl}/${endpoint}`,
              });
            }
            
            const jsonData = JSON.parse(responseData);
            
            // Forward response to client
            res.status(200).json({
              success: resSePay.statusCode >= 200 && resSePay.statusCode < 300,
              data: jsonData,
              statusCode: resSePay.statusCode,
            });
            resolve();
          } catch (e) {
            // If response is not JSON, return as text with error info
            console.error('Error parsing SePay response:', e);
            res.status(200).json({
              success: false,
              error: `Failed to parse SePay API response: ${e.message}`,
              data: responseData,
              statusCode: resSePay.statusCode,
              endpoint: endpoint,
              url: `${baseUrl}/${endpoint}`,
            });
            resolve();
          }
        });
      });

      reqSePay.on('error', (error) => {
        console.error('SePay API Proxy Error:', error);
        res.status(500).json({
          success: false,
          error: error.message,
        });
        resolve();
      });

      // Send request body for POST/PUT requests
      if ((method === 'POST' || method === 'PUT') && Object.keys(data).length > 0) {
        reqSePay.write(JSON.stringify(data));
      }

      reqSePay.end();
    });

  } catch (error) {
    console.error('SePay API Proxy Error:', error);
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

