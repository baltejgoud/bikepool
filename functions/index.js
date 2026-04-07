const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();


const twilio = require('twilio');

// Server-side pricing engine: distance + demand + vehicle type
exports.calculateFare = functions.https.onCall((data, context) => {
  const origin = data.origin || {};
  const destination = data.destination || {};
  const vehicleType = data.vehicleType || 'bike';
  const demand = Number(data.demand || 1.0);

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

  const surge = demand > 1 ? demand : 1;
  const fare = Math.round((fixed + distanceKm * baseRate) * surge);

  return {fare};
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
    console.error('Masked call error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
