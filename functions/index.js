const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret, defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

// Define secret parameter for SePay API token
const sepayApiToken = defineSecret("SEPAY_API_TOKEN");
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

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
exports.sepayWebhook = onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Handle GET requests (for testing/browser access)
  if (req.method === "GET") {
    return res.status(200).json({
      success: true,
      message: "SePay Webhook endpoint is active and ready to receive webhooks",
      endpoint: "sepayWebhook",
      method: "POST",
      testEndpoint:
        "https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayWebhookTest",
      note: "This endpoint only accepts POST requests from SePay. Use the test endpoint for GET requests.",
      timestamp: new Date().toISOString(),
    });
  }

  // Only accept POST requests for actual webhooks
  if (req.method !== "POST") {
    return res.status(405).json({
      success: false,
      error: "Method not allowed. Only POST requests are accepted.",
      allowedMethods: ["POST", "GET"],
      note: "GET requests return endpoint info. POST requests process webhooks.",
    });
  }

  try {
    console.log("SePay webhook received:", JSON.stringify(req.body, null, 2));

    // Parse webhook data from SePay
    const webhookData = req.body;

    // Extract and normalize fields
    const transferType = webhookData.transferType; // "in" for payment received, "out" for payment sent
    const transferAmount = parseFloat(webhookData.transferAmount || 0);
    const transactionDate =
      webhookData.transactionDate || webhookData.transferDate;
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
      const text = `${content || ""} ${description || ""}`;
      // Match patterns like "Order ABC123", "order 12345", "ORDER-XYZ"
      const orderMatch = text.match(/order[\s:-]*([A-Za-z0-9_-]{6,})/i);
      if (orderMatch && orderMatch[1]) {
        referenceNumber = orderMatch[1];
      }
    }

    if (!referenceNumber) {
      console.error(
        "Unable to determine invoice ID (code/content missing or unparsable)"
      );
      return res.status(400).json({
        success: false,
        error: "Missing invoice reference (code/content)",
      });
    }

    console.log(
      `Processing webhook for invoice: ${referenceNumber}, type: ${transferType}, amount: ${transferAmount}`
    );

    // Only process incoming payments (transferType === "in")
    if (transferType !== "in") {
      console.log(
        `Ignoring outgoing transaction for invoice: ${referenceNumber}`
      );
      return res.status(200).json({
        success: true,
        message: "Ignored outgoing transaction",
      });
    }

    // Find invoice by reference number (order ID)
    // The invoice ID should match the referenceCode
    const invoiceRef = admin
      .firestore()
      .collection("sales_invoices")
      .doc(referenceNumber);

    const invoiceDoc = await invoiceRef.get();

    if (!invoiceDoc.exists) {
      console.error(`Invoice not found: ${referenceNumber}`);
      return res.status(404).json({
        success: false,
        error: `Invoice not found: ${referenceNumber}`,
      });
    }

    const invoiceData = invoiceDoc.data();

    // Check if invoice is already paid
    if (invoiceData.paymentStatus === "paid") {
      console.log(
        `Invoice ${referenceNumber} is already paid, skipping update`
      );
      return res.status(200).json({
        success: true,
        message: "Invoice already paid",
      });
    }

    // Verify payment amount matches invoice total (DB stores thousands → convert to VND)
    const invoiceAmount = Number(invoiceData.totalPrice || 0) * 1000;
    const paymentAmount = transferAmount;

    console.log(
      `Comparing amounts - Invoice: ${invoiceAmount} VND, Payment: ${paymentAmount} VND`
    );

    // Allow small tolerance for rounding (e.g., 100 VND)
    const tolerance = 100;
    if (Math.abs(paymentAmount - invoiceAmount) > tolerance) {
      console.error(
        `Payment amount mismatch: expected ${invoiceAmount}, received ${paymentAmount}`
      );
      return res.status(400).json({
        success: false,
        error: `Payment amount mismatch: expected ${invoiceAmount} VND, received ${paymentAmount} VND`,
      });
    }

    // Update invoice payment status to paid
    // Use existing invoice 'date' as the paymentDate as requested
    const updateData = {
      paymentStatus: "paid",
      paymentMethod: "sepay",
      // Do not persist SePay-specific transient fields or separate paymentDate
      // The invoice 'date' field is considered the canonical time
    };

    await invoiceRef.update(updateData);

    console.log(
      `Successfully updated invoice ${referenceNumber} to paid status`
    );

    // Mark this webhook as processed for idempotency
    // Return success response to SePay
    return res.status(200).json({
      success: true,
      message: "Payment processed successfully",
      invoiceId: referenceNumber,
    });
  } catch (error) {
    console.error("Error processing SePay webhook:", error);
    console.error("Error stack:", error.stack);

    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Test endpoint to verify webhook is working
 *
 * URL: https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayWebhookTest
 */
exports.sepayWebhookTest = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  return res.status(200).json({
    success: true,
    message: "SePay webhook endpoint is working",
    timestamp: new Date().toISOString(),
    projectId: "se121p11-gizmoglobe",
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
exports.sepayApiProxy = onRequest(
  { secrets: [sepayApiToken] },
  async (req, res) => {
    // Enable CORS
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    // Handle preflight requests
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    // Handle GET requests (for testing)
    if (req.method === "GET") {
      return res.status(200).json({
        success: true,
        message: "SePay API Proxy is active",
        endpoint: "sepayApiProxy",
        usage: "POST requests with endpoint, method, and data",
        timestamp: new Date().toISOString(),
      });
    }

    try {
      // Get SePay API token from secret
      const apiToken = sepayApiToken.value();

      if (!apiToken) {
        console.error("SePay API token not configured");
        return res.status(500).json({
          success: false,
          error:
            "SePay API token not configured. Set it using: firebase functions:secrets:set SEPAY_API_TOKEN",
          note: "See https://firebase.google.com/docs/functions/config-env for more info",
        });
      }

      const baseUrl = "https://my.sepay.vn/userapi";
      const endpoint = req.body.endpoint;
      const method = req.body.method || "GET";
      const data = req.body.data || {};

      if (!endpoint) {
        return res.status(400).json({
          success: false,
          error: "Missing endpoint in request body",
        });
      }

      console.log(`SePay API Proxy: ${method} ${baseUrl}/${endpoint}`);

      // Use Node.js https module to make request to SePay API
      const https = require("https");
      const url = require("url");

      const sepayUrl = new URL(`${baseUrl}/${endpoint}`);

      // Add query parameters for GET requests
      if (method === "GET" && Object.keys(data).length > 0) {
        Object.keys(data).forEach((key) => {
          sepayUrl.searchParams.append(key, data[key]);
        });
      }

      const options = {
        hostname: sepayUrl.hostname,
        port: 443,
        path: sepayUrl.pathname + sepayUrl.search,
        method: method,
        headers: {
          Authorization: `Bearer ${apiToken}`,
          "Content-Type": "application/json",
        },
      };

      // Make request to SePay API
      return new Promise((resolve, reject) => {
        const reqSePay = https.request(options, (resSePay) => {
          let responseData = "";

          resSePay.on("data", (chunk) => {
            responseData += chunk;
          });

          resSePay.on("end", () => {
            try {
              // Log response for debugging
              console.log(
                `SePay API Response: ${resSePay.statusCode}`,
                responseData.substring(0, 500)
              );

              // If status code is error, include error details
              if (resSePay.statusCode >= 400) {
                return res.status(200).json({
                  success: false,
                  error: `SePay API returned ${resSePay.statusCode}`,
                  data: responseData || "",
                  statusCode: resSePay.statusCode,
                  endpoint: endpoint,
                  url: `${baseUrl}/${endpoint}`,
                });
              }

              const jsonData = JSON.parse(responseData);

              // Forward response to client
              res.status(200).json({
                success:
                  resSePay.statusCode >= 200 && resSePay.statusCode < 300,
                data: jsonData,
                statusCode: resSePay.statusCode,
              });
              resolve();
            } catch (e) {
              // If response is not JSON, return as text with error info
              console.error("Error parsing SePay response:", e);
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

        reqSePay.on("error", (error) => {
          console.error("SePay API Proxy Error:", error);
          res.status(500).json({
            success: false,
            error: error.message,
          });
          resolve();
        });

        // Send request body for POST/PUT requests
        if (
          (method === "POST" || method === "PUT") &&
          Object.keys(data).length > 0
        ) {
          reqSePay.write(JSON.stringify(data));
        }

        reqSePay.end();
      }); // This closes the Promise
    } catch (error) {
      console.error("SePay API Proxy Error:", error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * Product Rating Aggregation Functions
 *
 * These functions aggregate product ratings to avoid recalculating on each product load.
 * Aggregated data is stored in: aggregations/product_ratings
 *
 * Structure:
 * {
 *   "products": {
 *     "productID": {
 *       "avgRating": 4.5,
 *       "ratingCount": 120,
 *       "lastUpdated": timestamp
 *     }
 *   },
 *   "lastFullRecalc": timestamp
 * }
 */

/**
 * Helper function to aggregate ratings for a single product
 * @param {string} productId - The product ID to aggregate ratings for
 */
async function aggregateProductRating(productId) {
  try {
    if (!productId || productId.trim().length === 0) {
      console.log("Invalid productId provided to aggregateProductRating");
      return;
    }

    console.log(`Aggregating ratings for product: ${productId}`);

    // Query all ratings for this product
    const ratingsSnapshot = await admin
      .firestore()
      .collection("order_ratings")
      .where("productID", "==", productId)
      .get();

    let sum = 0;
    let count = 0;

    // Calculate sum and count
    ratingsSnapshot.forEach((doc) => {
      const data = doc.data();
      const rating = data.rating;

      // Parse rating value (handle different types)
      let parsedRating = 0;
      if (typeof rating === "number") {
        parsedRating = rating;
      } else if (typeof rating === "string") {
        parsedRating = parseInt(rating, 10) || 0;
      }

      if (parsedRating > 0) {
        sum += parsedRating;
        count += 1;
      }
    });

    const avgRating = count > 0 ? Math.round((sum / count) * 10) / 10 : 0;

    // Update aggregations/product_ratings document
    const aggregationsRef = admin
      .firestore()
      .collection("aggregations")
      .doc("productRatings");

    // Get current document to preserve other products
    const currentDoc = await aggregationsRef.get();
    const currentData = currentDoc.exists ? currentDoc.data() : {};
    const products = currentData.products || {};

    // Update the specific product in the products map
    products[productId] = {
      avgRating: avgRating,
      ratingCount: count,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Write back the entire products map
    await aggregationsRef.set(
      {
        products: products,
      },
      { merge: true }
    );

    console.log(
      `Updated rating aggregation for product ${productId}: avg=${avgRating.toFixed(
        2
      )}, count=${count}`
    );
  } catch (error) {
    console.error(`Error aggregating ratings for product ${productId}:`, error);
    throw error;
  }
}

/**
 * Firestore Trigger: Update product rating aggregation when rating is created, updated, or deleted
 *
 * Triggers on: order_ratings collection changes
 */
exports.onRatingWritten = onDocumentWritten(
  "order_ratings/{ratingId}",
  async (event) => {
    try {
      // Get productID from the rating document
      let productId = null;

      if (event.data.after) {
        // Document was created or updated
        const newData = event.data.after.data();
        productId = newData.productID || newData.productId;
      } else if (event.data.before) {
        // Document was deleted
        const oldData = event.data.before.data();
        productId = oldData.productID || oldData.productId;
      }

      if (!productId) {
        console.log(
          "No productID found in rating document, skipping aggregation"
        );
        return null;
      }

      console.log(
        `Rating changed for product ${productId}, triggering aggregation`
      );
      await aggregateProductRating(productId);

      return null;
    } catch (error) {
      console.error("Error in onRatingWritten trigger:", error);
      // Don't throw - allow the rating operation to succeed even if aggregation fails
      return null;
    }
  }
);

/**
 * Scheduled Function: Recalculate all product ratings daily at midnight (Asia/Bangkok timezone)
 *
 * Schedule: Every day at 00:00 Bangkok time (17:00 UTC previous day)
 * Timezone: Asia/Bangkok (UTC+7)
 */
exports.dailyRatingsRecalc = onSchedule(
  {
    schedule: "0 0 * * *", // Midnight every day
    timeZone: "Asia/Bangkok",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (event) => {
    try {
      console.log("Starting daily product ratings recalculation...");
      const startTime = Date.now();

      // Get all unique productIDs from order_ratings
      const ratingsSnapshot = await admin
        .firestore()
        .collection("order_ratings")
        .get();

      const productIds = new Set();
      ratingsSnapshot.forEach((doc) => {
        const data = doc.data();
        const productId = data.productID || data.productId;
        if (productId && productId.trim().length > 0) {
          productIds.add(productId);
        }
      });

      console.log(`Found ${productIds.size} unique products with ratings`);

      // Aggregate ratings for each product
      let successCount = 0;
      let errorCount = 0;

      for (const productId of productIds) {
        try {
          await aggregateProductRating(productId);
          successCount++;
        } catch (error) {
          console.error(
            `Failed to aggregate ratings for product ${productId}:`,
            error
          );
          errorCount++;
        }
      }

      // Update lastFullRecalc timestamp
      await admin
        .firestore()
        .collection("aggregations")
        .doc("productRatings")
        .set(
          {
            lastFullRecalc: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log(`Daily ratings recalculation completed in ${duration}s`);
      console.log(`Success: ${successCount}, Errors: ${errorCount}`);

      return null;
    } catch (error) {
      console.error("Error in dailyRatingsRecalc:", error);
      throw error;
    }
  }
);

// =============================================================================
// PRODUCT SIMILARITY & RECOMMENDATION FUNCTIONS
// =============================================================================

/**
 * Track Product View
 * Records when a user views a product for collaborative filtering.
 */
exports.trackProductView = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    return res
      .status(405)
      .json({ success: false, error: "Method not allowed" });
  }

  try {
    const { userId, productId, sessionId } = req.body;

    if (!productId) {
      return res
        .status(400)
        .json({ success: false, error: "Missing productId" });
    }

    await admin
      .firestore()
      .collection("product_views")
      .add({
        userId: userId || "anonymous",
        productId: productId,
        sessionId: sessionId || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("Error tracking product view:", error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * Track Vertex AI Event
 *
 * Receives user events from Flutter app and forwards them to Vertex AI Retail API.
 * This helps improve recommendation quality and tracks user engagement.
 *
 * Event types supported:
 * - search: When user searches or filters products
 * - detail-page-view: When user views a product detail page
 *
 * POST /trackVertexAIEvent
 */
exports.trackVertexAIEvent = onRequest(
  {
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      return res
        .status(405)
        .json({ success: false, error: "Method not allowed" });
    }

    try {
      const { eventType, visitorId, productDetails, searchQuery, filters } =
        req.body;

      // Validate required fields
      if (!eventType || !visitorId) {
        return res.status(400).json({
          success: false,
          error: "Missing required fields: eventType, visitorId",
        });
      }

      // Validate event type
      if (!["search", "detail-page-view"].includes(eventType)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid eventType. Must be "search" or "detail-page-view"',
        });
      }

      // Initialize Vertex AI Retail API client
      const { UserEventServiceClient } = require("@google-cloud/retail");
      const client = new UserEventServiceClient();

      const projectId = "413433346211"; // Numeric project ID
      const location = "global";
      const catalogId = "default_catalog";
      const parent = `projects/${projectId}/locations/${location}/catalogs/${catalogId}`;

      // Build user event object with proper Timestamp format
      const now = new Date();
      const userEvent = {
        eventType: eventType,
        visitorId: visitorId,
        eventTime: {
          seconds: Math.floor(now.getTime() / 1000),
          nanos: (now.getTime() % 1000) * 1000000,
        },
      };

      // Add event-specific fields
      if (eventType === "detail-page-view") {
        if (
          !productDetails ||
          !Array.isArray(productDetails) ||
          productDetails.length === 0
        ) {
          return res.status(400).json({
            success: false,
            error: "productDetails is required for detail-page-view events",
          });
        }
        userEvent.productDetails = productDetails;
      }

      if (eventType === "search") {
        if (!searchQuery || searchQuery.trim() === "") {
          return res.status(400).json({
            success: false,
            error: "searchQuery is required for search events",
          });
        }
        userEvent.searchQuery = searchQuery.trim();

        // Add filter information if provided
        if (filters && Array.isArray(filters) && filters.length > 0) {
          userEvent.filter = filters.join(" AND ");
        }
      }

      // Send event to Vertex AI Retail API
      console.log("Sending event to Vertex AI:", JSON.stringify(userEvent));

      const [response] = await client.writeUserEvent({
        parent: parent,
        userEvent: userEvent,
      });

      console.log("Event tracked successfully:", eventType);

      return res.status(200).json({
        success: true,
        eventType: eventType,
        message: "Event tracked to Vertex AI",
      });
    } catch (error) {
      console.error("Error tracking Vertex AI event:", error);
      return res.status(500).json({
        success: false,
        error: error.message,
        details: error.details || null,
      });
    }
  }
);

/**
 * Compute Product Similarity (Collaborative Filtering)
 * Scheduled function that computes similarity based on co-purchase patterns.
 */
exports.computeProductSimilarity = onSchedule(
  {
    schedule: "0 */6 * * *",
    timeZone: "Asia/Bangkok",
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (event) => {
    try {
      console.log("Starting product similarity computation...");
      const startTime = Date.now();

      const invoicesSnapshot = await admin
        .firestore()
        .collection("sales_invoices")
        .get();

      const coPurchaseMatrix = new Map();
      const purchaseCounts = new Map();

      for (const invoiceDoc of invoicesSnapshot.docs) {
        const invoiceId = invoiceDoc.id;

        const detailsSnapshot = await admin
          .firestore()
          .collection("sales_invoice_details")
          .where("salesInvoiceID", "==", invoiceId)
          .get();

        const productIds = detailsSnapshot.docs
          .map((d) => d.data().productID)
          .filter(Boolean);

        for (const productId of productIds) {
          purchaseCounts.set(
            productId,
            (purchaseCounts.get(productId) || 0) + 1
          );
        }

        for (let i = 0; i < productIds.length; i++) {
          for (let j = 0; j < productIds.length; j++) {
            if (i !== j) {
              const productA = productIds[i];
              const productB = productIds[j];

              if (!coPurchaseMatrix.has(productA)) {
                coPurchaseMatrix.set(productA, new Map());
              }
              coPurchaseMatrix
                .get(productA)
                .set(
                  productB,
                  (coPurchaseMatrix.get(productA).get(productB) || 0) + 1
                );
            }
          }
        }
      }

      console.log(
        "Built co-purchase matrix for " + coPurchaseMatrix.size + " products"
      );

      let batchCount = 0;
      let batch = admin.firestore().batch();

      for (const [productId, coProducts] of coPurchaseMatrix) {
        const productPurchases = purchaseCounts.get(productId) || 1;

        const similarities = [];
        for (const [coProductId, coCount] of coProducts) {
          const coProductPurchases = purchaseCounts.get(coProductId) || 1;
          const union = productPurchases + coProductPurchases - coCount;
          const score = coCount / Math.max(union, 1);

          similarities.push({
            productId: coProductId,
            score: Math.round(score * 1000) / 1000,
            coPurchaseCount: coCount,
            reason: "co-purchase",
          });
        }

        similarities.sort((a, b) => b.score - a.score);
        const topSimilar = similarities.slice(0, 20);

        const docRef = admin
          .firestore()
          .collection("product_similarity")
          .doc(productId);

        batch.set(docRef, {
          productId: productId,
          similar: topSimilar,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          algorithm: "collaborative-filtering",
        });

        batchCount++;

        if (batchCount >= 400) {
          await batch.commit();
          batch = admin.firestore().batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log("Similarity computation completed in " + duration + "s");

      await admin
        .firestore()
        .collection("aggregations")
        .doc("productSimilarity")
        .set(
          {
            lastComputation: admin.firestore.FieldValue.serverTimestamp(),
            productCount: coPurchaseMatrix.size,
          },
          { merge: true }
        );

      return null;
    } catch (error) {
      console.error("Error computing product similarity:", error);
      throw error;
    }
  }
);

/**
 * Get Similar Products API
 */
exports.getSimilarProducts = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const productId = req.query.productId || req.body?.productId;
    const limit = parseInt(req.query.limit || req.body?.limit || "10");

    if (!productId) {
      return res
        .status(400)
        .json({ success: false, error: "Missing productId" });
    }

    const configDoc = await admin
      .firestore()
      .collection("config")
      .doc("recommendations")
      .get();

    const config = configDoc.exists ? configDoc.data() : {};

    if (config.vertexAIEnabled) {
      const vertexDoc = await admin
        .firestore()
        .collection("vertex_recommendations")
        .doc(productId)
        .get();

      if (vertexDoc.exists) {
        return res.status(200).json({
          success: true,
          source: "vertex-ai",
          similar: (vertexDoc.data().similar || []).slice(0, limit),
        });
      }
    }

    const similarityDoc = await admin
      .firestore()
      .collection("product_similarity")
      .doc(productId)
      .get();

    if (similarityDoc.exists) {
      return res.status(200).json({
        success: true,
        source: "collaborative-filtering",
        similar: (similarityDoc.data().similar || []).slice(0, limit),
      });
    }

    return res.status(200).json({
      success: true,
      source: "none",
      similar: [],
    });
  } catch (error) {
    console.error("Error getting similar products:", error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * Vertex AI Recommendation API
 *
 * Calls the Retail API to get product recommendations.
 *
 * Query params:
 * - productId: The product to get recommendations for
 * - visitorId: (optional) User/visitor ID for personalization
 * - limit: (optional) Number of recommendations (default: 10)
 * - type: (optional) "similar" or "recently_viewed" (default: "similar")
 */
exports.getVertexAIRecommendations = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const productId = req.query.productId || req.body?.productId;
    const visitorId =
      req.query.visitorId || req.body?.visitorId || "anonymous-" + Date.now();
    const limit = parseInt(req.query.limit || req.body?.limit || "10");
    const type = req.query.type || req.body?.type || "similar";

    if (!productId && type === "similar") {
      return res.status(400).json({
        success: false,
        error: "productId is required for similar items recommendations",
      });
    }

    const { PredictionServiceClient } = require("@google-cloud/retail");
    const client = new PredictionServiceClient();

    const projectId = "413433346211"; // Numeric project ID
    const location = "global";
    const catalogId = "default_catalog";

    // Determine serving config based on type
    let servingConfigId;
    if (type === "recently_viewed") {
      servingConfigId = "recently_viewed_default";
    } else {
      // Use the similar items serving config
      servingConfigId = "similar-items-serving";
    }

    const placement = `projects/${projectId}/locations/${location}/catalogs/${catalogId}/servingConfigs/${servingConfigId}`;

    const request = {
      placement: placement,
      visitorId: visitorId,
      pageSize: limit,
    };

    // For similar items, add the product detail
    if (type === "similar" && productId) {
      request.productDetails = [
        {
          product: {
            id: productId,
          },
          quantity: { value: 1 },
        },
      ];
    }

    console.log("Calling Retail API with request:", JSON.stringify(request));

    const [response] = await client.predict(request);

    // Extract product IDs from results
    const recommendations = (response.results || []).map((result) => ({
      productId: result.id,
      score: result.metadata?.score || null,
    }));

    console.log("Got " + recommendations.length + " recommendations");

    return res.status(200).json({
      success: true,
      source: "vertex-ai",
      servingConfig: servingConfigId,
      recommendations: recommendations,
      attributionToken: response.attributionToken,
    });
  } catch (error) {
    console.error("Error getting Vertex AI recommendations:", error);
    return res.status(500).json({
      success: false,
      error: error.message,
      details: error.details || null,
    });
  }
});

/**
 * Cache Vertex AI Recommendations
 *
 * Scheduled function that fetches Vertex AI recommendations for all products
 * and caches them in Firestore for fast access.
 *
 * Runs every 12 hours to keep recommendations fresh.
 */
exports.cacheVertexAIRecommendations = onSchedule(
  {
    schedule: "0 */12 * * *", // Every 12 hours
    timeZone: "Asia/Bangkok",
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (event) => {
    try {
      console.log("Starting Vertex AI recommendations caching...");
      const startTime = Date.now();

      // Check if Vertex AI is enabled
      const configDoc = await admin
        .firestore()
        .collection("config")
        .doc("recommendations")
        .get();

      if (!configDoc.exists || !configDoc.data()?.vertexAIEnabled) {
        console.log("Vertex AI is disabled in config, skipping cache");
        return null;
      }

      const config = configDoc.data();
      const servingConfigId = config.servingConfigId || "similar-items-serving";

      // Get all products
      const productsSnapshot = await admin
        .firestore()
        .collection("products")
        .get();

      console.log(
        `Caching recommendations for ${productsSnapshot.size} products...`
      );

      const { PredictionServiceClient } = require("@google-cloud/retail");
      const client = new PredictionServiceClient();

      const projectId = "413433346211"; // Numeric project ID
      const location = "global";
      const catalogId = "default_catalog";
      const placement = `projects/${projectId}/locations/${location}/catalogs/${catalogId}/servingConfigs/${servingConfigId}`;

      let successCount = 0;
      let errorCount = 0;
      let batch = admin.firestore().batch();
      let batchCount = 0;

      for (const doc of productsSnapshot.docs) {
        try {
          const productId = doc.id;

          const request = {
            placement: placement,
            userEvent: {
              eventType: "detail-page-view",
              visitorId: "batch-caching-" + Date.now(),
              productDetails: [
                {
                  product: { id: productId },
                },
              ],
            },
            pageSize: 20,
          };

          const [response] = await client.predict(request);

          // Extract product IDs from results
          const similarIds = (response.results || []).map(
            (result) => result.id
          );

          if (similarIds.length > 0) {
            const cacheRef = admin
              .firestore()
              .collection("vertex_recommendations")
              .doc(productId);

            batch.set(cacheRef, {
              productId: productId,
              similar: similarIds,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
              servingConfig: servingConfigId,
              source: "vertex-ai",
            });

            batchCount++;
            successCount++;

            // Commit batch every 400 writes
            if (batchCount >= 400) {
              await batch.commit();
              batch = admin.firestore().batch();
              batchCount = 0;
            }
          }

          // Rate limiting: wait 100ms between requests to avoid quota issues
          await new Promise((resolve) => setTimeout(resolve, 100));
        } catch (error) {
          console.error(
            `Error getting recommendations for product ${doc.id}:`,
            error.message
          );
          errorCount++;
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

      // Update metadata
      await admin
        .firestore()
        .collection("aggregations")
        .doc("vertexRecommendations")
        .set(
          {
            lastCached: admin.firestore.FieldValue.serverTimestamp(),
            cachedCount: successCount,
            errorCount: errorCount,
          },
          { merge: true }
        );

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log(`Vertex AI caching completed in ${duration}s`);
      console.log(`Success: ${successCount}, Errors: ${errorCount}`);

      return null;
    } catch (error) {
      console.error("Error caching Vertex AI recommendations:", error);
      throw error;
    }
  }
);

/**
 * Trigger Vertex AI caching manually (HTTP endpoint)
 *
 * Call this endpoint to immediately cache recommendations for all products.
 * Useful for initial setup or testing.
 *
 * POST /triggerVertexAICaching
 */
exports.triggerVertexAICaching = onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      console.log("Manual Vertex AI caching triggered");

      // Check if Vertex AI is enabled
      const configDoc = await admin
        .firestore()
        .collection("config")
        .doc("recommendations")
        .get();

      if (!configDoc.exists || !configDoc.data()?.vertexAIEnabled) {
        return res.status(400).json({
          success: false,
          error: "Vertex AI is disabled in config/recommendations",
        });
      }

      const config = configDoc.data();
      const servingConfigId = config.servingConfigId || "similar-items-serving";
      const startTime = Date.now();

      // Get all products
      const productsSnapshot = await admin
        .firestore()
        .collection("products")
        .get();

      console.log(
        `Caching recommendations for ${productsSnapshot.size} products...`
      );

      const { PredictionServiceClient } = require("@google-cloud/retail");
      const client = new PredictionServiceClient();

      const projectId = "413433346211"; // Numeric project ID
      const location = "global";
      const catalogId = "default_catalog";
      const placement = `projects/${projectId}/locations/${location}/catalogs/${catalogId}/servingConfigs/${servingConfigId}`;

      let successCount = 0;
      let errorCount = 0;
      let batch = admin.firestore().batch();
      let batchCount = 0;

      for (const doc of productsSnapshot.docs) {
        try {
          const productId = doc.id;

          const request = {
            placement: placement,
            userEvent: {
              eventType: "detail-page-view",
              visitorId: "manual-caching-" + Date.now(),
              productDetails: [
                {
                  product: { id: productId },
                },
              ],
            },
            pageSize: 20,
          };

          const [response] = await client.predict(request);
          const similarIds = (response.results || []).map(
            (result) => result.id
          );

          if (similarIds.length > 0) {
            const cacheRef = admin
              .firestore()
              .collection("vertex_recommendations")
              .doc(productId);

            batch.set(cacheRef, {
              productId: productId,
              similar: similarIds,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
              servingConfig: servingConfigId,
              source: "vertex-ai",
            });

            batchCount++;
            successCount++;

            if (batchCount >= 400) {
              await batch.commit();
              batch = admin.firestore().batch();
              batchCount = 0;
            }
          }

          // Rate limiting
          await new Promise((resolve) => setTimeout(resolve, 100));
        } catch (error) {
          console.error(`Error for product ${doc.id}:`, error.message);
          errorCount++;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      await admin
        .firestore()
        .collection("aggregations")
        .doc("vertexRecommendations")
        .set(
          {
            lastCached: admin.firestore.FieldValue.serverTimestamp(),
            cachedCount: successCount,
            errorCount: errorCount,
          },
          { merge: true }
        );

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);

      return res.status(200).json({
        success: true,
        message: "Vertex AI caching completed",
        duration: duration + "s",
        productsProcessed: productsSnapshot.size,
        successCount: successCount,
        errorCount: errorCount,
      });
    } catch (error) {
      console.error("Error in manual caching:", error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

// =============================================================================
// VERTEX AI - PRODUCT EXPORT TO BIGQUERY
// =============================================================================

/**
 * Export Products to BigQuery for Retail API Import
 *
 * This function exports all products from Firestore to BigQuery in the
 * format required by Vertex AI Retail API.
 *
 * Call this endpoint to trigger a full product export:
 * POST /exportProductsToBigQuery
 */
exports.exportProductsToBigQuery = onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      console.log("Starting product export to BigQuery...");
      const startTime = Date.now();

      // Get all products from Firestore
      const productsSnapshot = await admin
        .firestore()
        .collection("products")
        .get();

      console.log("Found " + productsSnapshot.size + " products to export");

      // Get all manufacturers for lookup
      const manufacturersSnapshot = await admin
        .firestore()
        .collection("manufacturers")
        .get();

      const manufacturersMap = {};
      manufacturersSnapshot.forEach((doc) => {
        manufacturersMap[doc.id] = doc.data().manufacturerName || "Unknown";
      });

      console.log(
        "Loaded " + Object.keys(manufacturersMap).length + " manufacturers"
      );

      // Transform products to Retail API format
      const products = [];
      const timestamp = new Date().toISOString();

      productsSnapshot.forEach((doc) => {
        const data = doc.data();
        const productId = doc.id;

        // Build description from both English and Vietnamese descriptions
        let description = "";
        if (data.enDescription) {
          description = data.enDescription;
        } else if (data.viDescription) {
          description = data.viDescription;
        } else {
          // Fallback: generate description from product name and category
          description = `${data.productName || "Product"} - ${
            data.category || "Electronics"
          }`;
        }

        // Get manufacturer name from manufacturers collection
        const manufacturerId = data.manufacturer;
        const manufacturerName = manufacturersMap[manufacturerId] || "Unknown";

        // Handle price correctly:
        // - sellingPrice: current price in thousands VND (e.g., 1776 = 1,776,000 VND)
        // - discount: percentage (e.g., 33 = 33%)
        // - Calculate original price from selling price and discount
        const sellingPrice = data.sellingPrice || 0;
        const discountPercent = data.discount || 0;

        // Calculate original price: if discount is 33%, selling price is 67% of original
        // Original = sellingPrice / (1 - discount/100)
        let originalPrice = sellingPrice;
        if (discountPercent > 0) {
          originalPrice = Math.round(
            sellingPrice / (1 - discountPercent / 100)
          );
        }

        // Convert to actual VND (multiply by 1000)
        const priceInVND = sellingPrice * 1000;
        const originalPriceInVND = originalPrice * 1000;

        // Map to Retail API product schema
        products.push({
          id: productId,
          name:
            "projects/se121p11-gizmoglobe/locations/global/catalogs/default_catalog/branches/default_branch/products/" +
            productId,
          title: data.productName || "Unknown Product",
          description: description,
          categories: [data.category || "uncategorized"],
          brands: [manufacturerName],
          priceInfo: {
            currencyCode: "VND",
            price: priceInVND,
            originalPrice: originalPriceInVND,
          },
          availability: data.stock > 0 ? "IN_STOCK" : "OUT_OF_STOCK",
          availableQuantity: data.stock || 0,
          uri: "https://gizmoglobe.com/products/" + productId,
          images: data.imageUrl
            ? [{ uri: data.imageUrl, width: 500, height: 500 }]
            : [],
          attributes: {
            manufacturer: { text: [manufacturerName] },
            category: { text: [data.category || "uncategorized"] },
            price_range: { text: [getPriceRange(sellingPrice)] },
            stock_status: {
              text: [data.stock > 0 ? "in_stock" : "out_of_stock"],
            },
            discount: { numbers: [discountPercent] },
          },
          retrievableFields:
            "id,title,description,categories,brands,priceInfo,availability,attributes",
          publishTime: timestamp,
        });
      });

      // Helper function to categorize price ranges
      function getPriceRange(price) {
        if (price < 500) return "budget";
        if (price < 2000) return "mid_range";
        if (price < 5000) return "premium";
        return "high_end";
      }

      // Store in Firestore for now (can be extended to BigQuery later)
      // This creates a collection that can be exported to BigQuery using the extension
      const batch = admin.firestore().batch();

      for (const product of products) {
        const docRef = admin
          .firestore()
          .collection("retail_products_export")
          .doc(product.id);
        batch.set(docRef, product);
      }

      await batch.commit();

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log("Product export completed in " + duration + "s");

      return res.status(200).json({
        success: true,
        message: "Exported " + products.length + " products",
        duration: duration + "s",
        collection: "retail_products_export",
      });
    } catch (error) {
      console.error("Error exporting products:", error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * Export User Events to BigQuery for Retail API
 *
 * Exports purchase events in Retail API format.
 */
exports.exportUserEventsToBigQuery = onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");

    try {
      console.log("Starting user events export...");
      const startTime = Date.now();

      // Get all completed sales invoices
      const invoicesSnapshot = await admin
        .firestore()
        .collection("sales_invoices")
        .get();

      const userEvents = [];
      const timestamp = new Date().toISOString();

      for (const invoiceDoc of invoicesSnapshot.docs) {
        const invoice = invoiceDoc.data();
        const invoiceId = invoiceDoc.id;

        // Get invoice details
        const detailsSnapshot = await admin
          .firestore()
          .collection("sales_invoice_details")
          .where("salesInvoiceID", "==", invoiceId)
          .get();

        if (detailsSnapshot.empty) continue;

        const productDetails = detailsSnapshot.docs.map((d) => {
          const detail = d.data();
          return {
            product: { id: detail.productID },
            quantity: { value: detail.quantity || 1 },
          };
        });

        userEvents.push({
          eventType: "purchase-complete",
          visitorId: invoice.customerID || "anonymous",
          eventTime: invoice.date
            ? invoice.date.toDate().toISOString()
            : timestamp,
          productDetails: productDetails,
          attributionToken: invoiceId,
        });
      }

      // Store in Firestore collection for export
      const batch = admin.firestore().batch();
      let count = 0;

      for (const event of userEvents) {
        const docRef = admin
          .firestore()
          .collection("retail_events_export")
          .doc();
        batch.set(docRef, event);
        count++;

        if (count % 400 === 0) {
          await batch.commit();
        }
      }

      if (count % 400 !== 0) {
        await batch.commit();
      }

      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log("User events export completed in " + duration + "s");

      return res.status(200).json({
        success: true,
        message: "Exported " + userEvents.length + " user events",
        duration: duration + "s",
      });
    } catch (error) {
      console.error("Error exporting user events:", error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * Export Firestore products directly to BigQuery table
 * for Retail API import with exact schema match
 */
exports.exportToBigQueryTable = onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const { BigQuery } = require("@google-cloud/bigquery");
      const bigquery = new BigQuery({ projectId: "se121p11-gizmoglobe" });

      // First, fetch all manufacturers to create a lookup map
      console.log("Fetching manufacturers...");
      const manufacturersSnapshot = await admin
        .firestore()
        .collection("manufacturers")
        .get();
      const manufacturerMap = {};
      manufacturersSnapshot.forEach((doc) => {
        const data = doc.data();
        manufacturerMap[doc.id] = data.manufacturerName || "Unknown";
      });
      console.log(
        "Found " + Object.keys(manufacturerMap).length + " manufacturers"
      );

      console.log("Fetching products from Firestore...");
      const snapshot = await admin.firestore().collection("products").get();
      console.log("Found " + snapshot.size + " products");

      // Transform to Retail API schema for BigQuery
      // Schema must match: id, title, categories (REPEATED), priceInfo (STRUCT)
      const rows = [];
      snapshot.forEach((doc) => {
        const p = doc.data();
        const productId = doc.id;

        // Only include active products
        if (p.status !== "active") return;

        // Get manufacturer name from lookup map
        // Products store manufacturer as ID in 'manufacturer' field
        const manufacturerId = p.manufacturer;
        const manufacturerName =
          manufacturerId && manufacturerMap[manufacturerId]
            ? manufacturerMap[manufacturerId]
            : "Unknown";

        // Calculate price values
        // sellingPrice is stored as 1000 to mean 1,000,000 VND (x1000 format)
        const sellingPrice = (parseFloat(p.sellingPrice) || 0) * 1000;
        const discount = parseFloat(p.discount) || 0;
        const discountedPrice = sellingPrice * (1 - discount / 100);

        rows.push({
          id: productId,
          title: p.productName || "Unknown Product",
          categories: [p.category || "uncategorized"], // REPEATED STRING
          priceInfo: {
            currencyCode: "VND",
            price: discountedPrice,
            originalPrice: sellingPrice,
          },
          availability: p.stock > 0 ? "IN_STOCK" : "OUT_OF_STOCK",
          availableQuantity: p.stock || 0,
          uri: "https://gizmoglobe.com/products/" + productId,
          brands: [manufacturerName],
        });
      });

      const dataset = bigquery.dataset("recommendations");
      const tableName = "retail_products";

      // Schema matching Vertex AI Retail API product schema
      const schema = [
        { name: "id", type: "STRING", mode: "REQUIRED" },
        { name: "title", type: "STRING", mode: "REQUIRED" },
        { name: "categories", type: "STRING", mode: "REPEATED" },
        {
          name: "priceInfo",
          type: "RECORD",
          fields: [
            { name: "currencyCode", type: "STRING" },
            { name: "price", type: "FLOAT" },
            { name: "originalPrice", type: "FLOAT" },
          ],
        },
        { name: "availability", type: "STRING" },
        { name: "availableQuantity", type: "INTEGER" },
        { name: "uri", type: "STRING" },
        { name: "brands", type: "STRING", mode: "REPEATED" },
      ];

      const table = dataset.table(tableName);

      // Try to delete existing table, ignore if it doesn't exist
      try {
        console.log("Attempting to delete existing table...");
        await table.delete();
        console.log("Table deleted");
      } catch (e) {
        console.log("Table did not exist or could not be deleted:", e.message);
      }

      // Wait a moment for deletion to propagate
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Create fresh table
      console.log("Creating table with Retail API schema...");
      await dataset.createTable(tableName, { schema });
      console.log("Table created");

      // Wait for table to be available
      await new Promise((resolve) => setTimeout(resolve, 3000));

      // Insert in batches
      const batchSize = 100;

      for (let i = 0; i < rows.length; i += batchSize) {
        const batch = rows.slice(i, i + batchSize);
        await table.insert(batch);
        console.log(
          "Inserted batch " +
            (Math.floor(i / batchSize) + 1) +
            " (" +
            batch.length +
            " rows)"
        );
      }

      console.log("Export complete!");
      return res.status(200).json({
        success: true,
        message: "Exported " + rows.length + " products to BigQuery",
        table: "se121p11-gizmoglobe.recommendations.retail_products",
        schema: "Vertex AI Retail API compatible",
      });
    } catch (error) {
      console.error("Error:", error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

// =============================================================================
// GEMINI API PROXY
// =============================================================================

/**
 * Gemini API Proxy
 *
 * Proxies Gemini AI API calls from the client to keep GEMINI_API_KEY secure.
 * This function receives the prompt from client and returns AI response.
 *
 * URL: https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/geminiProxy
 */
exports.geminiProxy = onRequest(
  {
    secrets: [geminiApiKey],
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      return res.status(405).json({ success: false, error: "Use POST" });
    }

    try {
      const apiKey = geminiApiKey.value();
      if (!apiKey) {
        return res.status(500).json({ success: false, error: "Gemini API key not configured" });
      }

      const { prompt } = req.body;
      if (!prompt || prompt.trim() === "") {
        return res.status(400).json({ success: false, error: "Missing prompt" });
      }

      const https = require("https");
      const requestBody = {
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 1, topK: 40, topP: 0.95, maxOutputTokens: 8192 },
      };
      const postData = JSON.stringify(requestBody);

      const options = {
        hostname: "generativelanguage.googleapis.com",
        port: 443,
        path: `/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(postData),
        },
      };

      return new Promise((resolve) => {
        const geminiReq = https.request(options, (geminiRes) => {
          let responseData = "";
          geminiRes.on("data", (chunk) => { responseData += chunk; });
          geminiRes.on("end", () => {
            try {
              const jsonData = JSON.parse(responseData);
              if (geminiRes.statusCode >= 400) {
                res.status(200).json({ success: false, error: jsonData.error?.message || "Gemini API error" });
                return resolve();
              }
              const text = jsonData.candidates?.[0]?.content?.parts?.[0]?.text || "";
              res.status(200).json({ success: true, response: text });
              resolve();
            } catch (e) {
              res.status(500).json({ success: false, error: "Failed to parse Gemini response" });
              resolve();
            }
          });
        });
        geminiReq.on("error", (error) => {
          res.status(500).json({ success: false, error: error.message });
          resolve();
        });
        geminiReq.write(postData);
        geminiReq.end();
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
);

// =============================================================================
// STRIPE API PROXY
// =============================================================================

/**
 * Stripe API Proxy
 *
 * Proxies Stripe API calls from the client to keep STRIPE_SECRET_KEY secure.
 *
 * URL: https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/stripeProxy
 */
exports.stripeProxy = onRequest(
  {
    secrets: [stripeSecretKey],
    timeoutSeconds: 60,
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      console.log(`Stripe Proxy: Received ${req.method} instead of POST. URL: ${req.url}, Headers:`, req.headers);
      return res.status(405).json({ 
        success: false, 
        error: "Use POST",
        receivedMethod: req.method,
        url: req.url
      });
    }

    try {
      const secretKey = stripeSecretKey.value();
      if (!secretKey) {
        return res.status(500).json({ success: false, error: "Stripe secret key not configured" });
      }

      // Log request for debugging
      console.log("Stripe Proxy request:", {
        method: req.method,
        contentType: req.get("Content-Type"),
        bodyKeys: req.body ? Object.keys(req.body) : "no body",
        body: JSON.stringify(req.body).substring(0, 500)
      });

      const { action, amount, currency, paymentIntentId, paymentMethodId } = req.body;
      if (!action) {
        console.log("Stripe Proxy: Missing action. Body:", JSON.stringify(req.body));
        return res.status(400).json({ success: false, error: "Missing action" });
      }
      
      console.log(`Stripe Proxy: Action=${action}, Body keys:`, Object.keys(req.body));

      const https = require("https");
      const stripeRequest = (method, path, data) => {
        return new Promise((resolve, reject) => {
          const postData = data ? Object.entries(data).map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`).join("&") : "";
          const options = {
            hostname: "api.stripe.com",
            port: 443,
            path: path,
            method: method,
            headers: {
              Authorization: `Bearer ${secretKey}`,
              "Content-Type": "application/x-www-form-urlencoded",
            },
          };
          if (method === "POST" && postData) options.headers["Content-Length"] = Buffer.byteLength(postData);

          const stripeReq = https.request(options, (stripeRes) => {
            let responseData = "";
            stripeRes.on("data", (chunk) => { responseData += chunk; });
            stripeRes.on("end", () => {
              try {
                const jsonData = JSON.parse(responseData);
                if (stripeRes.statusCode >= 400) {
                  console.log(`Stripe API Error (${stripeRes.statusCode}):`, jsonData);
                  reject(jsonData.error || jsonData);
                } else {
                  resolve(jsonData);
                }
              } catch (e) { 
                console.error("Failed to parse Stripe response:", e, responseData);
                reject({ message: "Failed to parse Stripe response", raw: responseData }); 
              }
            });
          });
          stripeReq.on("error", reject);
          if (method === "POST" && postData) stripeReq.write(postData);
          stripeReq.end();
        });
      };

      let result;
      switch (action) {
        case "createPaymentIntent":
          if (!amount || !currency) return res.status(400).json({ success: false, error: "Missing amount or currency" });
          result = await stripeRequest("POST", "/v1/payment_intents", { amount: String(amount), currency: currency.toLowerCase(), "payment_method_types[]": "card" });
          return res.status(200).json({ success: true, paymentIntent: { id: result.id, clientSecret: result.client_secret, status: result.status, amount: result.amount, currency: result.currency } });

        case "confirmPayment":
          if (!paymentIntentId) return res.status(400).json({ success: false, error: "Missing paymentIntentId" });
          const confirmData = {};
          if (paymentMethodId) confirmData.payment_method = paymentMethodId;
          result = await stripeRequest("POST", `/v1/payment_intents/${paymentIntentId}/confirm`, confirmData);
          return res.status(200).json({ success: true, paymentIntent: { id: result.id, status: result.status } });

        case "getPaymentIntent":
          if (!paymentIntentId) return res.status(400).json({ success: false, error: "Missing paymentIntentId" });
          result = await stripeRequest("GET", `/v1/payment_intents/${paymentIntentId}`, null);
          return res.status(200).json({ success: true, paymentIntent: { id: result.id, status: result.status, amount: result.amount, currency: result.currency } });

        case "createCheckoutSession":
          const { successUrl, cancelUrl, lineItems } = req.body;
          console.log("Stripe Proxy createCheckoutSession:", { 
            hasSuccessUrl: !!successUrl, 
            hasCancelUrl: !!cancelUrl, 
            hasLineItems: !!lineItems,
            lineItemsType: typeof lineItems,
            lineItemsKeys: lineItems ? Object.keys(lineItems) : null
          });
          if (!successUrl || !cancelUrl) {
            return res.status(400).json({ success: false, error: "Missing successUrl or cancelUrl" });
          }
          if (!lineItems || typeof lineItems !== 'object' || Object.keys(lineItems).length === 0) {
            return res.status(400).json({ 
              success: false, 
              error: "Missing or invalid lineItems",
              received: { lineItems, type: typeof lineItems, keys: lineItems ? Object.keys(lineItems) : null }
            });
          }
          // Build form data for checkout session - lineItems is already a flat object with keys like "line_items[0][price_data][currency]"
          const sessionData = {
            "payment_method_types[]": "card",
            "mode": "payment",
            "success_url": successUrl,
            "cancel_url": cancelUrl,
            ...lineItems
          };
          console.log("Stripe Proxy sessionData keys:", Object.keys(sessionData));
          try {
            result = await stripeRequest("POST", "/v1/checkout/sessions", sessionData);
            return res.status(200).json({ success: true, session: { id: result.id, url: result.url } });
          } catch (stripeError) {
            console.error("Stripe API error in createCheckoutSession:", stripeError);
            return res.status(200).json({ 
              success: false, 
              error: stripeError.message || "Stripe API error",
              details: stripeError
            });
          }

        case "getCheckoutSession":
          const { sessionId } = req.body;
          if (!sessionId) return res.status(400).json({ success: false, error: "Missing sessionId" });
          result = await stripeRequest("GET", `/v1/checkout/sessions/${sessionId}`, null);
          return res.status(200).json({ success: true, session: result });

        default:
          return res.status(400).json({ success: false, error: `Unknown action: ${action}` });
      }
    } catch (error) {
      console.error("Stripe Proxy error:", error);
      return res.status(500).json({ 
        success: false, 
        error: error.message || "Stripe API error",
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
      });
    }
  }
);
