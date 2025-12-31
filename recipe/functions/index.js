/**
 * Firebase Cloud Functions for Recipe Smart App
 * 
 * This file contains Cloud Functions that:
 * 1. Send daily expiry alerts for pantry items expiring within 3 days
 * 
 * Prerequisites:
 * - Firebase CLI installed: npm install -g firebase-tools
 * - Firebase project initialized: firebase init functions
 * - Dependencies installed: cd functions && npm install
 * 
 * Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

// Configuration constants
const EXPIRY_ALERT_DAYS = 3;
const BATCH_SIZE = 100; // Process users in batches for better performance

/**
 * Shared function to process expiry alerts for all users
 * Optimized with pagination and better error handling
 */
async function processExpiryAlerts() {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const nowDate = now.toDate();
  let totalNotificationsSent = 0;
  let lastDoc = null;
  let processedUsers = 0;

  // Process users in batches for better performance and scalability
  // Note: Firestore doesn't efficiently support != null queries, so we filter in code
  while (true) {
    let usersQuery = db.collection('users').limit(BATCH_SIZE);

    if (lastDoc) {
      usersQuery = usersQuery.startAfter(lastDoc);
    }

    const usersSnapshot = await usersQuery.get();

    if (usersSnapshot.empty) {
      break; // No more users to process
    }

    // Process users in parallel batches
    const userPromises = usersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        return null;
      }

      try {
        // Get user's pantry items with expiration dates
        const pantryItemsSnapshot = await db
          .collection('users')
          .doc(userId)
          .collection('pantry_items')
          .where('expirationDate', '!=', null)
          .get();

        const expiringItems = [];

        pantryItemsSnapshot.forEach((doc) => {
          const item = doc.data();
          const expirationDate = item.expirationDate;

          if (expirationDate) {
            const expDate = expirationDate.toDate();
            const daysUntilExpiration = Math.ceil(
              (expDate.getTime() - nowDate.getTime()) / (1000 * 60 * 60 * 24)
            );

            // Items expiring within configured days (including today)
            if (daysUntilExpiration >= 0 && daysUntilExpiration <= EXPIRY_ALERT_DAYS) {
              expiringItems.push({
                id: doc.id,
                name: item.name,
                expirationDate: expDate,
                daysUntilExpiration: daysUntilExpiration,
              });
            }
          }
        });

        // Send notification if there are expiring items
        if (expiringItems.length > 0) {
          const notificationResult = await sendExpiryNotification(
            userId,
            fcmToken,
            expiringItems,
            db
          );
          return notificationResult;
        }

        return null;
      } catch (error) {
        console.error(`Error processing user ${userId}:`, error);
        return null;
      }
    });

    const results = await Promise.allSettled(userPromises);
    results.forEach((result) => {
      if (result.status === 'fulfilled' && result.value === true) {
        totalNotificationsSent++;
      }
    });

    processedUsers += usersSnapshot.docs.length;
    lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];

    // If we got fewer results than the batch size, we've reached the end
    if (usersSnapshot.docs.length < BATCH_SIZE) {
      break;
    }
  }

  console.log(
    `Expiry alert check completed. Processed ${processedUsers} users, sent ${totalNotificationsSent} notifications.`
  );
  return { totalNotificationsSent, processedUsers };
}

/**
 * Send expiry notification to a user
 */
async function sendExpiryNotification(userId, fcmToken, expiringItems, db) {
  const itemCount = expiringItems.length;
  const itemNames = expiringItems
    .slice(0, 3)
    .map((item) => item.name)
    .join(', ');
  const moreText = itemCount > 3 ? ` and ${itemCount - 3} more` : '';

  const title = itemCount === 1
    ? 'Item Expiring Soon!'
    : `${itemCount} Items Expiring Soon!`;

  const body = itemCount === 1
    ? `${expiringItems[0].name} expires ${expiringItems[0].daysUntilExpiration === 0 ? 'today' : `in ${expiringItems[0].daysUntilExpiration} day${expiringItems[0].daysUntilExpiration > 1 ? 's' : ''}`}`
    : `${itemNames}${moreText} ${itemCount === 1 ? 'expires' : 'expire'} soon. Check your pantry!`;

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: 'pantry_expiry',
      itemCount: itemCount.toString(),
      userId: userId,
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'pantry_alerts',
        priority: 'high',
        visibility: 'public',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: itemCount,
          alert: {
            title: title,
            body: body,
          },
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    console.log(`Notification sent to user ${userId} for ${itemCount} expiring items`);
    return true;
  } catch (error) {
    console.error(`Failed to send notification to user ${userId}:`, error);

    // If token is invalid, remove it from user document
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      try {
        await db.collection('users').doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
        console.log(`Removed invalid FCM token for user ${userId}`);
      } catch (updateError) {
        console.error(`Failed to remove invalid token for user ${userId}:`, updateError);
      }
    }
    return false;
  }
}

/**
 * Daily scheduled function to check for expiring pantry items
 * Runs every day at 9:00 AM UTC
 * 
 * To change schedule, modify the cron expression:
 * - "0 9 * * *" = Every day at 9:00 AM UTC
 * - "0 9 * * 1" = Every Monday at 9:00 AM UTC
 * - "*/30 * * * *" = Every 30 minutes (for testing)
 */
exports.sendExpiryAlerts = functions.pubsub
  .schedule('0 9 * * *') // Every day at 9:00 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Starting daily expiry alert check...');

    try {
      const result = await processExpiryAlerts();
      console.log(`Completed: ${result.totalNotificationsSent} notifications sent to ${result.processedUsers} users`);
      return null;
    } catch (error) {
      console.error('Error in sendExpiryAlerts:', error);
      throw error;
    }
  });

/**
 * HTTP function to manually trigger expiry alerts (for testing)
 * 
 * Usage: POST to https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/manualExpiryAlerts
 * 
 * Note: This requires authentication in production. Add authentication middleware.
 */
exports.manualExpiryAlerts = functions.https.onRequest(async (req, res) => {
  // For security, you should add authentication here
  // if (req.headers.authorization !== 'Bearer YOUR_SECRET') {
  //   res.status(401).send('Unauthorized');
  //   return;
  // }

  try {
    const result = await processExpiryAlerts();
    res.status(200).json({
      success: true,
      notificationsSent: result.totalNotificationsSent,
      usersProcessed: result.processedUsers,
      message: `Sent ${result.totalNotificationsSent} notifications to ${result.processedUsers} users`,
    });
  } catch (error) {
    console.error('Error in manualExpiryAlerts:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

