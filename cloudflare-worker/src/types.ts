export interface Env {
  FIREBASE_PROJECT_ID: string;
  FIREBASE_CLIENT_EMAIL: string;
  FIREBASE_PRIVATE_KEY: string;
  // No longer used to authenticate mobile clients (they present a Firebase
  // ID token). Retained as optional for compatibility with existing secrets;
  // it is NOT required for notification requests.
  WORKER_AUTH_SECRET?: string;
}

export interface SendNotificationRequest {
  recipientId: string;
  chatId: string;
  senderId: string;
  senderName: string;
  messagePreview: string;
  productTitle: string;
  recipientRole: 'Buyer' | 'Seller';
}

export interface SendNotificationResponse {
  success: boolean;
  sentCount?: number;
  failedTokens?: string[];
  error?: string;
}

export interface FCMMessage {
  message: {
    token: string;
    notification: {
      title: string;
      body: string;
    };
    data: Record<string, string>;
    android: {
      priority: 'high' | 'normal';
      notification: {
        channelId: string;
        icon: string;
        color: string;
        sound?: string;
      };
    };
    apns: {
      payload: {
        aps: {
          alert: {
            title: string;
            body: string;
          };
          sound: string;
          badge: number;
        };
      };
    };
  };
}

export interface FCMTokenResponse {
  access_token: string;
  expires_in: number;
  token_type: string;
}