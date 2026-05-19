const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const Razorpay = require('razorpay');

admin.initializeApp();


const twilio = require('twilio');

// Lazily initialize Razorpay inside each function call to avoid top-level
// module crashes if environment variables are not yet available at startup.
function getRazorpayInstance() {
  const keyId = process.env.RAZORPAY_KEY_ID || 'rzp_test_Sqj3CAj9RGWFfc';
  const keySecret = process.env.RAZORPAY_KEY_SECRET || 'Mg2SBlSeY0XBuxktDTWKAt0O';
  console.log('Razorpay Key ID present:', !!keyId);
  return new Razorpay({ key_id: keyId, key_secret: keySecret });
}

// Server-side AI Pricing engine: predicts demand based on historical data
exports.calculateFare = functions.https.onCall(async (data, context) => {
  // Authentication guard — reject unauthenticated callers
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be signed in to calculate fare.'
    );
  }

  const origin = data.origin || {};
  const destination = data.destination || {};
  const vehicleType = data.vehicleType || 'bike';

  // Input validation
  if (vehicleType !== 'car' && vehicleType !== 'bike') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'vehicleType must be "car" or "bike".'
    );
  }
  if (!origin.lat || !origin.lng || !destination.lat || !destination.lng) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'origin and destination must each have lat and lng.'
    );
  }
  
  // 1. Fetch historical data to simulate ML demand prediction
  const now = new Date();
  const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);
  
  try {
    const recentRidesSnapshot = await admin.firestore()
      .collection('rides')
      .where('startTime', '>=', admin.firestore.Timestamp.fromDate(twoHoursAgo))
      .get();
      
    const recentRidesCount = recentRidesSnapshot.size;
    
    // ML Simulation: Demand multiplier scales with recent activity
    // Base demand is 1.0. Every 5 rides in the last 2 hours adds 0.1x to the demand, capped at 3.0x.
    let mlDemandFactor = 1.0 + (Math.floor(recentRidesCount / 5) * 0.1);
    mlDemandFactor = Math.min(mlDemandFactor, 3.0);

    const getMeters = (lat1, lng1, lat2, lng2) => {
      const toRad = (x) => (x * Math.PI) / 180;
      const R = 6371000;
      const dLat = toRad(lat2 - lat1);
      const dLng = toRad(lng2 - lng1);
      const a =
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLng/2) * Math.sin(dLng/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      return R * c;
    };

    const distanceMeters = getMeters(origin.lat, origin.lng, destination.lat, destination.lng);
    const distanceKm = Math.max(1, distanceMeters / 1000);

    const baseRate = vehicleType === 'car' ? 14 : 6; // per km
    const fixed = vehicleType === 'car' ? 40 : 20;

    const fare = Math.round((fixed + distanceKm * baseRate) * mlDemandFactor);

    return {
      fare,
      mlDemandFactor,
      recentRidesCount
    };
  } catch (error) {
    console.error('Error calculating fare with ML pricing:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Masked Calling Implementation
 * Requirements:
 * - Twilio SID, Auth Token and Proxy Service SID (or a Twilio Phone Number)
 * - Configured in Firebase environment variables or .env
 */
exports.initiateMaskedCall = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
  }

  const rideId = data.rideId;
  const callerUid = context.auth.uid;

  if (!rideId) {
    throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a rideId.');
  }

  try {
    // 1. Get Ride details
    const rideDoc = await admin.firestore().collection('rides').doc(rideId).get();
    if (!rideDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Ride not found.');
    }
    const ride = rideDoc.data();

    // 2. Determine parties (Driver and the first Rider)
    const driverUid = ride.driverUid;
    const riderUid = ride.riderUids && ride.riderUids.length > 0 ? ride.riderUids[0] : null;

    if (!driverUid || !riderUid) {
      throw new functions.https.HttpsError('failed-precondition', 'Ride does not have both driver and rider.');
    }

    // 3. Get phone numbers from user profiles
    const driverDoc = await admin.firestore().collection('users').doc(driverUid).get();
    const riderDoc = await admin.firestore().collection('users').doc(riderUid).get();

    const driverPhone = driverDoc.data()?.phoneNumber;
    const riderPhone = riderDoc.data()?.phoneNumber;

    if (!driverPhone || !riderPhone) {
      throw new functions.https.HttpsError('failed-precondition', 'One or both parties do not have a registered phone number.');
    }

    // 4. Initialize Twilio client
    // These should be set via `firebase functions:config:set twilio.sid="..." twilio.token="..."`
    const accountSid = process.env.TWILIO_ACCOUNT_SID || functions.config().twilio?.sid;
    const authToken = process.env.TWILIO_AUTH_TOKEN || functions.config().twilio?.token;
    const twilioNumber = process.env.TWILIO_PHONE_NUMBER || functions.config().twilio?.phone;

    if (!accountSid || !authToken || !twilioNumber) {
      console.warn('Twilio credentials missing. Using mock response.');
      return {
        success: true,
        message: 'Mock: Masked call initiated between ' + callerUid + ' and paired user.',
        proxyNumber: '+1234567890 (MOCK)',
      };
    }

    const client = twilio(accountSid, authToken);

    // 5. Create a call to the caller first, which then connects to the other party
    // Simple implementation: connect caller to proxy, then proxy to target
    // For true masking, usually Twilio Proxy Service is used, but a simple Voice URL
    // can also work by calling both parties and merging.
    
    // Target is the person the caller is NOT.
    const targetPhone = (callerUid === driverUid) ? riderPhone : driverPhone;

    // This is a simplified version using an TwiML Bin or dynamic TwiML
    const call = await client.calls.create({
      twiml: `<Response><Dial callerId="${twilioNumber}">${targetPhone}</Dial></Response>`,
      to: (callerUid === driverUid) ? driverPhone : riderPhone,
      from: twilioNumber,
    });

    return {
      success: true,
      callSid: call.sid,
      proxyNumber: twilioNumber,
    };

  } catch (error) {
    // Log full error server-side for debugging, but return a sanitized
    // message to the client to prevent leaking Twilio credentials or
    // internal stack traces.
    console.error('Masked call error:', error);
    
    // If it's already an HttpsError we threw above, re-throw it as-is
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to initiate masked call. Please try again later.'
    );
  }
});

/**
 * Razorpay Integration
 */

// 1. Create Order (plain HTTPS — accepts Firebase ID token in Authorization header)
// This avoids the Firebase Android SDK's callable Pigeon bridge bug.
exports.createRazorpayOrder = functions.region('us-central1').https.onRequest(async (req, res) => {
  // Handle CORS preflight
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'POST') { res.status(405).json({ error: { message: 'Method not allowed' } }); return; }

  // --- Auth: verify Firebase ID token from Authorization header ---
  const authHeader = req.headers['authorization'] || '';
  const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!idToken) {
    res.status(401).json({ error: { status: 'UNAUTHENTICATED', message: 'Missing Authorization header' } });
    return;
  }

  let uid;
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    uid = decoded.uid;
  } catch (authErr) {
    console.error('Token verification failed:', authErr.message);
    res.status(401).json({ error: { status: 'UNAUTHENTICATED', message: 'Invalid or expired token' } });
    return;
  }

  // --- Validate input ---
  const body = req.body || {};
  const amount = (body.data && body.data.amount) ? Number(body.data.amount) : Number(body.amount);
  if (!amount || amount <= 0 || isNaN(amount)) {
    res.status(400).json({ error: { status: 'INVALID_ARGUMENT', message: 'Valid amount is required' } });
    return;
  }

  // --- Create Razorpay order ---
  try {
    const razorpay = getRazorpayInstance();
    const options = {
      amount: Math.round(amount * 100), // paise
      currency: 'INR',
      receipt: `receipt_${uid}_${Date.now()}`,
      notes: { uid },
    };
    const order = await razorpay.orders.create(options);
    console.log('Order created:', order.id, 'for uid:', uid);
    res.status(200).json({
      result: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
      }
    });
  } catch (error) {
    console.error('Razorpay order creation failed:', error);
    res.status(500).json({
      error: { status: 'INTERNAL', message: error.message || 'Failed to create Razorpay order' }
    });
  }
});


exports.razorpayWebhook = functions.https.onRequest(async (req, res) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET || functions.config().razorpay?.webhook_secret || 'mock_webhook_secret';
  
  const shasum = crypto.createHmac('sha256', secret);
  shasum.update(JSON.stringify(req.body));
  const digest = shasum.digest('hex');

  if (digest === req.headers['x-razorpay-signature']) {
    console.log('Request is legit');
    
    const event = req.body.event;
    if (event === 'payment.captured' || event === 'payment.authorized') {
      const payment = req.body.payload.payment.entity;
      const uid = payment.notes.uid;
      const amount = payment.amount / 100; // back to INR
      
      if (uid) {
        // Update user's wallet balance
        const userRef = admin.firestore().collection('users').doc(uid);
        await admin.firestore().runTransaction(async (transaction) => {
          const userDoc = await transaction.get(userRef);
          if (!userDoc.exists) return;
          
          const currentBalance = userDoc.data().walletBalance || 0;
          transaction.update(userRef, {
            walletBalance: currentBalance + amount
          });
          
          // Log transaction
          const txRef = admin.firestore().collection('users').doc(uid).collection('transactions').doc();
          transaction.set(txRef, {
            id: payment.id,
            amount: amount,
            type: 'CREDIT',
            title: 'Wallet top-up',
            subtitle: 'via Razorpay',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
      }
    }
    res.json({ status: 'ok' });
  } else {
    res.status(403).send('Invalid signature');
  }
});

// 3. Payout API for withdrawals
exports.createRazorpayPayout = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { amount, fundAccountId, mode = 'UPI' } = data;
  if (!amount || amount <= 0 || !fundAccountId) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid amount and account ID required');
  }

  const uid = context.auth.uid;
  const userRef = admin.firestore().collection('users').doc(uid);

  try {
    const result = await admin.firestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found');
      }
      
      const currentBalance = userDoc.data().walletBalance || 0;
      if (currentBalance < amount) {
        throw new functions.https.HttpsError('failed-precondition', 'Insufficient balance');
      }

      // In a real scenario, we'd call razorpayX payouts API here:
      // const payout = await razorpayX.payouts.create({
      //   account_number: '...', fund_account_id: fundAccountId, amount: amount * 100, ...
      // });
      
      // Deduct balance
      transaction.update(userRef, {
        walletBalance: currentBalance - amount
      });
      
      // Log transaction
      const txRef = admin.firestore().collection('users').doc(uid).collection('transactions').doc();
      transaction.set(txRef, {
        amount: amount,
        type: 'DEBIT',
        title: 'Withdrawal',
        subtitle: `via ${mode}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true };
    });

    return result;
  } catch (error) {
    console.error('Error processing payout:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to process withdrawal');
  }
});
