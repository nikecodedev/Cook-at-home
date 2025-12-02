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
      const db = admin.firestore();
      const now = admin.firestore.Timestamp.now();
      const threeDaysFromNow = new Date(now.toDate());
      threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);
      const threeDaysTimestamp = admin.firestore.Timestamp.fromDate(threeDaysFromNow);

      // Get all users
      const usersSnapshot = await db.collection('users').get();
      let totalNotificationsSent = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        // Skip if user doesn't have FCM token
        if (!fcmToken) {
          console.log(`Skipping user ${userId}: No FCM token`);
          continue;
        }

        // Get user's pantry items
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
            const nowDate = now.toDate();
            const daysUntilExpiration = Math.ceil(
              (expDate.getTime() - nowDate.getTime()) / (1000 * 60 * 60 * 24)
            );

            // Items expiring within 3 days (including today)
            if (daysUntilExpiration >= 0 && daysUntilExpiration <= 3) {
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
            totalNotificationsSent++;
          } catch (error) {
            console.error(`Failed to send notification to user ${userId}:`, error);
            
            // If token is invalid, remove it from user document
            if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
              await db.collection('users').doc(userId).update({
                fcmToken: admin.firestore.FieldValue.delete(),
              });
              console.log(`Removed invalid FCM token for user ${userId}`);
            }
          }
        }
      }

      console.log(`Expiry alert check completed. Sent ${totalNotificationsSent} notifications.`);
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
    // Call the same logic as the scheduled function
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const threeDaysFromNow = new Date(now.toDate());
    threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);
    const threeDaysTimestamp = admin.firestore.Timestamp.fromDate(threeDaysFromNow);

    const usersSnapshot = await db.collection('users').get();
    let totalNotificationsSent = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) continue;

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
          const nowDate = now.toDate();
          const daysUntilExpiration = Math.ceil(
            (expDate.getTime() - nowDate.getTime()) / (1000 * 60 * 60 * 24)
          );

          if (daysUntilExpiration >= 0 && daysUntilExpiration <= 3) {
            expiringItems.push({
              id: doc.id,
              name: item.name,
              expirationDate: expDate,
              daysUntilExpiration: daysUntilExpiration,
            });
          }
        }
      });

      if (expiringItems.length > 0) {
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
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: itemCount,
              },
            },
          },
        };

        try {
          await admin.messaging().send(message);
          totalNotificationsSent++;
        } catch (error) {
          console.error(`Failed to send notification to user ${userId}:`, error);
        }
      }
    }

    res.status(200).json({
      success: true,
      notificationsSent: totalNotificationsSent,
      message: `Sent ${totalNotificationsSent} notifications`,
    });
  } catch (error) {
    console.error('Error in manualExpiryAlerts:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

