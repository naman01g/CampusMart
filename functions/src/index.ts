import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

function isFirebaseError(error: unknown): error is { code: string } {
  return typeof error === 'object' && error !== null && 'code' in error;
}

const db = admin.firestore();
const messaging = admin.messaging();
const auth = admin.auth();

// AKGEC email domain constant
const AKGEC_EMAIL_DOMAIN = 'akgec.ac.in';

function isAKGECEmail(email: string): boolean {
  return email.toLowerCase().endsWith(`@${AKGEC_EMAIL_DOMAIN}`);
}

// Validate AKGEC email domain on user creation
export const onUserCreated = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const userId = context.params.userId;
    
    // Check if email is from AKGEC domain
    if (!userData.email || !isAKGECEmail(userData.email)) {
      console.warn(`User ${userId} created with non-AKGEC email: ${userData.email}. Deleting user.`);
      
      // Delete the user document
      await snap.ref.delete();
      
      // Also delete the Firebase Auth account
      try {
        await auth.deleteUser(userId);
        console.log(`Deleted Firebase Auth user ${userId} for non-AKGEC email`);
      } catch (error) {
        console.error(`Failed to delete Firebase Auth user ${userId}:`, error);
      }
      
      return;
    }
    
    // Ensure collegeId is set correctly
    if (userData.collegeId !== 'akgec') {
      await snap.ref.update({ collegeId: 'akgec' });
    }
    
    // Ensure role is student
    if (userData.role !== 'student') {
      await snap.ref.update({ role: 'student' });
    }
    
    // Ensure isVerified is false initially (email verification required)
    if (userData.isVerified === true) {
      await snap.ref.update({ isVerified: false });
    }
  });

// Send notification when new message received
export const onMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;
    const messageId = context.params.messageId;
    
    // Get chat details
    const chatSnap = await db.collection('chats').doc(chatId).get();
    if (!chatSnap.exists) return;
    
    const chat = chatSnap.data()!;
    const recipientId = message.senderId === chat.buyerId ? chat.sellerId : chat.buyerId;
    
    // Don't send notification to sender
    if (recipientId === message.senderId) return;
    
    // Get recipient's FCM token
    const userSnap = await db.collection('users').doc(recipientId).get();
    if (!userSnap.exists) return;
    
    const userData = userSnap.data()!;
    const fcmToken = userData.fcmToken;
    
    if (!fcmToken) return;
    
    // Get sender name
    const senderSnap = await db.collection('users').doc(message.senderId).get();
    const senderName = senderSnap.data()?.name || 'Someone';
    
    // Get product title
    const productSnap = await db.collection('products').doc(chat.productId).get();
    const productTitle = productSnap.data()?.title || 'a listing';
    
    // Send push notification
    try {
      await messaging.send({
        token: fcmToken,
        notification: {
          title: `New message from ${senderName}`,
          body: message.message.length > 50 
            ? message.message.substring(0, 50) + '...' 
            : message.message,
        },
        data: {
          chatId,
          messageId,
          productId: chat.productId,
          type: 'new_message',
        },
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });
    } catch (error) {
      console.error('Error sending notification:', error);
      // If token is invalid, remove it
      if (isFirebaseError(error) && error.code === 'messaging/invalid-registration-token') {
        await db.collection('users').doc(recipientId).update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }
  });

// Send notification when listing status changes
export const onListingStatusChanged = functions.firestore
  .document('products/{productId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.status === after.status) return;
    
    const productId = context.params.productId;
    
    // Notify seller if buyer reserved/bought
    if (after.status === 'RESERVED' || after.status === 'SOLD') {
      const sellerId = after.sellerId;
      const userSnap = await db.collection('users').doc(sellerId).get();
      if (!userSnap.exists) return;
      
      const userData = userSnap.data()!;
      const fcmToken = userData.fcmToken;
      
      if (!fcmToken) return;
      
      const statusText = after.status === 'RESERVED' ? 'reserved' : 'sold';
      
      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: 'Listing Update',
            body: `Your listing "${after.title}" has been ${statusText}!`,
          },
          data: {
            productId,
            type: 'listing_status',
            status: after.status,
          },
        });
      } catch (error) {
        console.error('Error sending listing notification:', error);
      }
    }
  });

// Clean up old notifications (run daily)
export const cleanupOldNotifications = functions.pubsub
  .schedule('0 3 * * *') // 3 AM daily
  .timeZone('UTC')
  .onRun(async () => {
    const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    );
    
    const snapshot = await db.collection('notifications')
      .where('createdAt', '<', thirtyDaysAgo)
      .where('isRead', '==', true)
      .limit(500)
      .get();
    
    if (snapshot.empty) return;
    
    const batch = db.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    
    console.log(`Deleted ${snapshot.size} old notifications`);
  });

// Update user verification status (admin only)
export const setUserVerified = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  // Check if caller is admin
  const callerSnap = await db.collection('users').doc(context.auth.uid).get();
  if (!callerSnap.exists || callerSnap.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }
  
  const { userId, verified } = data;
  if (!userId || typeof verified !== 'boolean') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing userId or verified');
  }
  
  await db.collection('users').doc(userId).update({
    isVerified: verified,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  return { success: true };
});

// Ban user (admin only)
export const banUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const callerSnap = await db.collection('users').doc(context.auth.uid).get();
  if (!callerSnap.exists || callerSnap.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }
  
  const { userId, reason } = data;
  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing userId');
  }
  
  // Disable auth account
  await auth.updateUser(userId, { disabled: true });
  
  // Update user record
  await db.collection('users').doc(userId).update({
    banned: true,
    banReason: reason || 'Violated community guidelines',
    bannedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  // Remove all their active listings
  const listingsSnap = await db.collection('products')
    .where('sellerId', '==', userId)
    .where('status', '==', 'ACTIVE')
    .get();
  
  const batch = db.batch();
  listingsSnap.docs.forEach(doc => {
    batch.update(doc.ref, { 
      status: 'REMOVED',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
  
  return { success: true };
});

// Resend verification email
export const resendVerificationEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const userId = context.auth.uid;
  
  try {
    // Send verification email via Firebase Auth
    const link = await auth.generateEmailVerificationLink(userId);
    // Note: In production, you'd send this link via email service
    // For now, we'll just return the link
    return { success: true, link };
  } catch (error) {
    console.error('Failed to resend verification email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send verification email');
  }
});

// Sync email verification status via scheduled function (runs every 5 minutes)
export const syncEmailVerification = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('UTC')
  .onRun(async () => {
    const usersSnap = await db.collection('users')
      .where('isVerified', '==', false)
      .limit(100)
      .get();
    
    if (usersSnap.empty) return;
    
    for (const doc of usersSnap.docs) {
      const userId = doc.id;
      try {
        const userRecord = await auth.getUser(userId);
        if (userRecord.emailVerified) {
          await db.collection('users').doc(userId).update({
            isVerified: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`Synced email verification for ${userId}: true`);
        }
      } catch (error) {
        console.error(`Failed to sync email verification for ${userId}:`, error);
      }
    }
  });