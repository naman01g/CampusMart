import { SignJWT, jwtVerify, createRemoteJWKSet, errors } from 'jose';
import { Env, SendNotificationRequest, SendNotificationResponse, FCMMessage, FCMTokenResponse } from './types';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const FIRESTORE_SCOPE = 'https://www.googleapis.com/auth/datastore';

// Public JWKS for Firebase Auth ID tokens (securetoken service account).
// Used to verify the signature/claims of the client's Firebase ID token.
const FIREBASE_AUTH_JWKS = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com')
);

function getFCMApiUrl(projectId: string): string {
  return `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
}

interface AccessTokenCache {
  token: string;
  expiresAt: number;
}

// Separate caches for FCM and Firestore tokens (different scopes). They are
// minted with distinct OAuth scopes and must never be shared.
let fcmAccessTokenCache: AccessTokenCache | null = null;
let firestoreAccessTokenCache: AccessTokenCache | null = null;

/// Mints a fresh OAuth2 access token using the service-account credentials for
/// a specific API scope. Tokens are cached per scope. No token value is logged.
async function mintAccessToken(env: Env, scope: string, cache: AccessTokenCache | null): Promise<{ token: string; expiresAt: number }> {
  const now = Date.now();

  const serviceAccount = {
    client_email: env.FIREBASE_CLIENT_EMAIL,
    private_key: (env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  };

  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    console.error('[FCM] service account credential: missing');
    throw new Error('Service account credential missing');
  }

  const nowSec = Math.floor(now / 1000);
  const expirySec = nowSec + 3600;

  const jwt = await new SignJWT({
    iss: serviceAccount.client_email,
    scope,
    aud: 'https://oauth2.googleapis.com/token',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuedAt(nowSec)
    .setExpirationTime(expirySec)
    .sign(await crypto.subtle.importKey(
      'pkcs8',
      decodePemPrivateKey(serviceAccount.private_key),
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign']
    ));

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('OAuth2 access token error:', error);
    throw new Error(`Failed to get access token: ${response.status}`);
  }

  const data = (await response.json()) as { access_token: string; expires_in: number };
  const entry: AccessTokenCache = {
    token: data.access_token,
    expiresAt: now + data.expires_in * 1000,
  };
  console.log(`[FCM] OAuth2 access token obtained (expires_in=${data.expires_in}s)`);
  return entry;
}

/// Returns a cached-or-fresh access token for a given API scope.
async function getScopedAccessToken(
  env: Env,
  scope: string,
  cacheSlot: () => AccessTokenCache | null,
  setCache: (c: AccessTokenCache) => void
): Promise<string> {
  const now = Date.now();
  const cached = cacheSlot();
  if (cached && cached.expiresAt > now + 60000) {
    return cached.token;
  }
  const entry = await mintAccessToken(env, scope, cached);
  setCache(entry);
  return entry.token;
}

/// FCM-scoped token (https://www.googleapis.com/auth/firebase.messaging).
async function getAccessToken(env: Env): Promise<string> {
  const cached = fcmAccessTokenCache;
  if (cached && cached.expiresAt > Date.now() + 60000) {
    console.log('[FCM] access token: using cached token');
    return cached.token;
  }
  console.log('[FCM] access token generation: starting');
  const token = await getScopedAccessToken(
    env,
    FCM_SCOPE,
    () => fcmAccessTokenCache,
    (c) => { fcmAccessTokenCache = c; }
  );
  console.log('[FCM] access token generation: success');
  return token;
}

/// Firestore/datastore-scoped token
/// (https://www.googleapis.com/auth/datastore).
async function getFirestoreAccessToken(env: Env): Promise<string> {
  const cached = firestoreAccessTokenCache;
  if (cached && cached.expiresAt > Date.now() + 60000) {
    console.log('[Firestore] access token: using cached token');
    return cached.token;
  }
  console.log('[Firestore] access token generation: starting');
  const token = await getScopedAccessToken(
    env,
    FIRESTORE_SCOPE,
    () => firestoreAccessTokenCache,
    (c) => { firestoreAccessTokenCache = c; }
  );
  console.log('[Firestore] access token generation: success');
  return token;
}

/// Returns the index of the first character that is not valid base64
/// (A-Za-z0-9+/ with up to two trailing '='), or -1 if all characters are
/// valid. Never returns or prints the offending character itself.
function findInvalidBase64Char(s: string): number {
  const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  const digits = '0123456789';
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (alpha.includes(c) || digits.includes(c) || c === '+' || c === '/') continue;
    if (c === '=') {
      // '=' may only appear at the very end, max twice.
      const trailing = s.slice(i);
      if (/^={1,2}$/.test(trailing)) break;
      return i;
    }
    return i;
  }
  return -1;
}

/// Decodes a PEM-encoded PKCS#8 private key into an ArrayBuffer for WebCrypto
/// import. It is robust to:
///   - escaped newlines (`\n` literal backslash-n vs real newlines)
///   - CRLF / stray whitespace
///   - optional or missing `=` padding
///   - standard base64 (`+`/`/`) or base64url (`-`/`_`) bodies
///
/// It validates every character before calling `atob()` and, when the input is
/// malformed, throws a controlled error that identifies the offending code
/// point WITHOUT exposing the character or the key itself.
function decodePemPrivateKey(pem: string): ArrayBuffer {
  const hasHeader = pem.includes('-----BEGIN PRIVATE KEY-----');
  const hasFooter = pem.includes('-----END PRIVATE KEY-----');

  // Normalize escaped newlines (literal backslash-n) to real newlines.
  const withRealNewlines = pem.replace(/\\n/g, '\n');

  // Isolate the base64 body between the PEM armor lines if present.
  const bodyMatch = withRealNewlines.match(
    /-----BEGIN PRIVATE KEY-----([\s\S]*?)-----END PRIVATE KEY-----/
  );
  const rawBody = bodyMatch ? bodyMatch[1] : withRealNewlines;

  // Strip all whitespace (space, tab, CR, LF).
  const compact = rawBody.replace(/\s+/g, '');

  console.log(`[FCM] private key PEM header found: ${hasHeader}`);
  console.log(`[FCM] private key PEM footer found: ${hasFooter}`);
  console.log(`[FCM] private key body length (compact): ${compact.length}`);

  if (compact.length === 0) {
    console.error('[FCM] private key parsing: malformed (empty body)');
    throw new Error('Private key parsing: empty PEM body');
  }

  // Detect whether the body is base64url (contains `-`/`_` but no `+`/`/`).
  const hasDashUnderscore = /[-_]/.test(compact);
  const hasPlusSlash = /[+/]/.test(compact);
  const usesBase64Url = hasDashUnderscore && !hasPlusSlash;
  console.log(`[FCM] private key body contains base64url chars: ${hasDashUnderscore}`);

  // Convert base64url -> base64 only when base64url is actually in use.
  const standard = hasDashUnderscore
    ? compact.replace(/-/g, '+').replace(/_/g, '/')
    : compact;

  // Validate the character set before decoding. Surfacing the code point (not
  // the character) pinpoints a malformed secret so it can be recreated safely.
  const invalidIdx = findInvalidBase64Char(standard);
  if (invalidIdx !== -1) {
    const code = standard.codePointAt(invalidIdx) as number;
    const hex = `U+${code.toString(16).toUpperCase().padStart(4, '0')}`;
    console.error(
      `[FCM] private key parsing: malformed (invalid char at index ${invalidIdx}, codepoint ${hex}, decimal ${code})`
    );
    throw new Error(
      `Private key parsing: invalid base64 character at index ${invalidIdx} (codepoint ${hex})`
    );
  }

  console.log(`[FCM] private key normalized length: ${standard.length}`);

  // Validate padding: at most two trailing '='.
  const trimEq = standard.replace(/=+$/, '');
  const padExisting = standard.length - trimEq.length;
  if (padExisting > 2) {
    console.error('[FCM] private key parsing: malformed (excessive padding)');
    throw new Error('Private key parsing: invalid base64 padding');
  }

  // Restore any required padding so atob() never chokes on an unpadded body.
  const rem = standard.length % 4;
  const padAdded = rem === 0 ? 0 : 4 - rem;
  const padded = rem === 0 ? standard : standard.padEnd(standard.length + padAdded, '=');
  console.log(`[FCM] private key padding added: ${padAdded}`);

  console.log('[FCM] private key decode: starting');
  let binary: string;
  try {
    binary = atob(padded);
  } catch (e) {
    const code = findInvalidBase64Char(padded);
    console.error(
      `[FCM] private key decode: malformed atob (first invalid index ${code})`
    );
    throw new Error(
      `Private key parsing: atob rejected base64 (first invalid index ${code})`
    );
  }
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  console.log('[FCM] private key decode: success');
  return bytes.buffer;
}

interface VerifiedAuth {
  uid: string;
}

/// Verifies the client's Firebase ID token and extracts the authenticated UID.
///
/// The token is validated against Firebase Auth's public keys (securetoken
/// JWKS) and the expected issuer/audience for this project, so the returned
/// UID cannot be forged or supplied by the client.
async function verifyFirebaseIdToken(authHeader: string | null, env: Env): Promise<VerifiedAuth | null> {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const idToken = authHeader.slice(7).trim();
  if (!idToken) return null;

  const projectId = env.FIREBASE_PROJECT_ID;
  try {
    const { payload } = await jwtVerify(idToken, FIREBASE_AUTH_JWKS, {
      audience: projectId,
      issuer: `https://securetoken.google.com/${projectId}`,
    });

    const uid = payload.sub;
    if (typeof uid !== 'string' || uid.length === 0) {
      return null;
    }

    return { uid };
  } catch (error) {
    if (error instanceof errors.JWTExpired) {
      console.log('Firebase ID token expired');
    } else if (error instanceof errors.JWTClaimValidationFailed) {
      console.log('Firebase ID token claim validation failed');
    } else {
      console.error('Firebase ID token verification failed:', error);
    }
    return null;
  }
}

function validatePayload(payload: unknown): payload is SendNotificationRequest {
  if (!payload || typeof payload !== 'object') return false;
  const p = payload as Record<string, unknown>;
  return (
    typeof p.recipientId === 'string' &&
    p.recipientId.length > 0 &&
    typeof p.chatId === 'string' &&
    p.chatId.length > 0 &&
    typeof p.senderId === 'string' &&
    p.senderId.length > 0 &&
    typeof p.senderName === 'string' &&
    typeof p.messagePreview === 'string' &&
    p.messagePreview.length > 0 &&
    typeof p.productTitle === 'string' &&
    typeof p.recipientRole === 'string' &&
    p.recipientRole.length > 0 &&
    p.senderId !== p.recipientId
  );
}

/// Whether an FCM error indicates a token is stale/unregistered (no longer
/// valid on a device). Such tokens should be removed from Firestore.
function isStaleTokenError(errorCode: string, message: string): boolean {
  return (
    errorCode === 'UNREGISTERED' ||
    errorCode === 'NOT_FOUND' ||
    /notregist/i.test(message) ||
    /not a valid fcm registration token/i.test(message)
  );
}

async function sendFCMNotification(
  accessToken: string,
  message: FCMMessage,
  projectId: string
): Promise<{ success: boolean; error?: string; httpStatus?: number; stale?: boolean }> {
  console.log(`[FCM] FCM request: sending`);
  const response = await fetch(getFCMApiUrl(projectId), {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  });

  console.log(`[FCM] FCM HTTP status: ${response.status}`);
  if (response.ok) {
    console.log(`[FCM] FCM response: SUCCESS`);
    return { success: true };
  }

  const errorData = await response.json().catch(() => ({}));
  const error = errorData.error?.message || `HTTP ${response.status}`;
  const errorCode = errorData.error?.status || 'UNKNOWN';
  const httpStatus = response.status;
  console.log(`[FCM] FCM response: ERROR (code=${errorCode}, message=${error})`);

  const stale = isStaleTokenError(errorCode, error);
  if (stale) {
    return { success: false, error: 'UNREGISTERED', httpStatus, stale };
  }

  return { success: false, error, httpStatus };
}

async function sendToMultipleTokens(
  accessToken: string,
  tokens: string[],
  payload: SendNotificationRequest,
  projectId: string
): Promise<{ successCount: number; failedTokens: string[]; staleTokens: string[] }> {
  let successCount = 0;
  const failedTokens: string[] = [];
  const staleTokens: string[] = [];

  console.log(`[FCM] recipient UID: ${payload.recipientId}`);
  console.log(`[FCM] registered tokens: ${tokens.length}`);

  for (const token of tokens) {
    const senderLabel = payload.senderName && payload.senderName.trim().length > 0
      ? payload.senderName
      : (payload.recipientRole === 'Buyer' ? 'Seller' : 'Buyer');
    
    const message: FCMMessage = {
      message: {
        token,
        notification: {
          title: 'CampusMart',
          body: `New message from ${senderLabel}: ${payload.messagePreview}`,
        },
        data: {
          chatId: payload.chatId,
          productTitle: payload.productTitle,
          senderId: payload.senderId,
          senderName: senderLabel,
          recipientRole: payload.recipientRole,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'campusmart_chat',
            icon: 'ic_launcher',
            color: '#CC8B26',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: 'CampusMart',
                body: `New message from ${senderLabel}: ${payload.messagePreview}`,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      },
    };

    const result = await sendFCMNotification(accessToken, message, projectId);
    if (result.success) {
      successCount++;
    } else if (result.stale) {
      staleTokens.push(token);
      console.log(`[FCM] a token is stale/unregistered (will be cleaned up)`);
    } else {
      failedTokens.push(token);
      console.error(`[FCM] delivery failed: ${result.error} (HTTP ${result.httpStatus})`);
    }
  }

  console.log(`[FCM] successful tokens: ${successCount}`);
  console.log(`[FCM] failed tokens: ${failedTokens.length}`);
  console.log(`[FCM] stale tokens to clean up: ${staleTokens.length}`);
  return { successCount, failedTokens, staleTokens };
}

/// Removes FCM tokens that FCM reported as stale/unregistered from the
/// recipient's `users/{uid}.fcmTokens` array. Uses a Firestore `removeAllFromArray`
/// transform so only the specific stale tokens are removed - valid tokens for
/// other devices and any concurrently-added tokens are preserved.
async function removeStaleTokensFromFirestore(
  accessToken: string,
  projectId: string,
  databaseId: string,
  uid: string,
  staleTokens: string[]
): Promise<void> {
  if (staleTokens.length === 0) return;

  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/${databaseId}/documents/users/${uid}` +
    `?updateMask.fieldPaths=fcmTokens`;

  const body = {
    updateTransforms: [
      {
        fieldPath: 'fcmTokens',
        removeAllFromArray: {
          values: staleTokens.map((t) => ({ stringValue: t })),
        },
      },
    ],
  };

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const err = await response.text().catch(() => '');
    console.error(
      `[FCM] failed to remove stale tokens (HTTP ${response.status}): ${err.slice(0, 200)}`
    );
  } else {
    console.log(`[FCM] removed ${staleTokens.length} stale token(s) for recipient`);
  }
}

/// Produces a log-safe copy of a Firestore REST response body:
///   - FCM token values are replaced with a redaction marker
///   - the document's `name` field is stripped of the trailing user UID
///   - the result is truncated to at most 1000 characters
/// Non-JSON bodies are only truncated. Never returns raw FCM tokens or UIDs.
function sanitizeFirestoreBody(bodyText: string): string {
  const truncated = (s: string) => (s.length > 1000 ? s.slice(0, 1000) : s);
  if (!bodyText || bodyText === '(unreadable)') return bodyText;

  let parsed: unknown;
  try {
    parsed = JSON.parse(bodyText);
  } catch {
    return truncated(bodyText);
  }
  if (typeof parsed !== 'object' || parsed === null) return truncated(bodyText);

  const doc = parsed as {
    name?: unknown;
    fields?: { fcmTokens?: { arrayValue?: { values?: Array<Record<string, unknown>> } } };
  };

  if (typeof doc.name === 'string') {
    doc.name = doc.name.replace(/\/documents\/users\/[^/]+$/, '/documents/users/[REDACTED]');
  }

  const tokenValues = doc.fields?.fcmTokens?.arrayValue?.values;
  if (Array.isArray(tokenValues)) {
    for (const tokenValue of tokenValues) {
      if (tokenValue && typeof tokenValue === 'object') {
        tokenValue.stringValue = '[REDACTED]';
      }
    }
  }

  return truncated(JSON.stringify(parsed));
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    if (path === '/health') {
      return Response.json({ status: 'ok', service: 'campusmart-notifications' });
    }

    if (path !== '/send-notification' || request.method !== 'POST') {
      return new Response('Not Found', { status: 404 });
    }

    // 1. Verify the client's Firebase Auth ID token first.
    const authHeader = request.headers.get('Authorization');
    const verifiedAuth = await verifyFirebaseIdToken(authHeader, env);
    if (!verifiedAuth) {
      console.log('[FCM] authentication: failed');
      return Response.json(
        { success: false, error: 'Unauthorized' },
        { status: 401 }
      );
    }
    console.log('[FCM] authentication: success');

    // 2. Extract the authenticated UID from the verified token.
    const verifiedUid = verifiedAuth.uid;

    // 3. Parse the request payload.
    let payload: unknown;
    try {
      payload = await request.json();
    } catch {
      return Response.json(
        { success: false, error: 'Invalid JSON' },
        { status: 400 }
      );
    }

    // 4. Validate the payload.
    if (!validatePayload(payload)) {
      return Response.json(
        { success: false, error: 'Invalid payload' },
        { status: 400 }
      );
    }

    // 5. Ignore/override any client-provided senderId with the verified UID.
    // The sender identity comes exclusively from the verified ID token.
    const notificationRequest = payload as SendNotificationRequest;
    notificationRequest.senderId = verifiedUid;

    // 6. Re-check that the verified sender is not the recipient.
    if (notificationRequest.senderId === notificationRequest.recipientId) {
      return Response.json(
        { success: false, error: 'Sender cannot notify themselves' },
        { status: 400 }
      );
    }

    try {
      // Firestore uses a datastore-scoped token; FCM uses its own token below.
      const firestoreAccessToken = await getFirestoreAccessToken(env);

      const firestoreProjectId = env.FIREBASE_PROJECT_ID;
      const firestoreDatabaseId = '(default)';
      const userDocUrl =
        `https://firestore.googleapis.com/v1/projects/${firestoreProjectId}` +
        `/databases/${firestoreDatabaseId}/documents/users/${notificationRequest.recipientId}`;

      console.log('[FCM] Firestore request:');
      console.log(`- project ID: ${firestoreProjectId}`);
      console.log(`- database ID: ${firestoreDatabaseId}`);
      console.log('- HTTP method: GET');
      console.log('- endpoint: firestore.googleapis.com/v1 (REST v1)');

      const userDoc = await fetch(userDocUrl, {
        method: 'GET',
        headers: { Authorization: `Bearer ${firestoreAccessToken}` },
      });

      const bodyText = await userDoc.text().catch(() => '(unreadable)');

      console.log(`- HTTP status: ${userDoc.status}`);
      console.log(`- HTTP status text: ${userDoc.statusText || '(empty)'}`);
      console.log(`- response Content-Type: ${userDoc.headers.get('content-type') || '(empty)'}`);
      console.log(`- response body (truncated to 1000 chars): ${sanitizeFirestoreBody(bodyText)}`);

      if (!userDoc.ok) {
        if (userDoc.status === 404) {
          return Response.json(
            { success: false, error: 'Recipient not found' },
            { status: 404 }
          );
        }
        throw new Error(`Failed to fetch user: ${userDoc.status}`);
      }

      let userData: {
        fields: { fcmTokens?: { arrayValue?: { values?: Array<{ stringValue: string }> } } };
      } = { fields: {} };
      try {
        userData = JSON.parse(bodyText);
      } catch {
        userData = { fields: {} };
      }

      const tokens = userData.fields.fcmTokens?.arrayValue?.values?.map(v => v.stringValue) || [];

      if (tokens.length === 0) {
        return Response.json(
          { success: false, error: 'No FCM tokens registered' },
          { status: 404 }
        );
      }

      // FCM delivery must use the FCM-scoped token, not the Firestore one.
      const fcmAccessToken = await getAccessToken(env);
      const result = await sendToMultipleTokens(fcmAccessToken, tokens, notificationRequest, env.FIREBASE_PROJECT_ID);

      // Best-effort cleanup: remove tokens FCM reported as stale/unregistered
      // from the recipient's document. Uses the datastore-scoped token.
      if (result.staleTokens.length > 0) {
        await removeStaleTokensFromFirestore(
          firestoreAccessToken,
          firestoreProjectId,
          firestoreDatabaseId,
          notificationRequest.recipientId,
          result.staleTokens
        );
      }

      const responseBody: SendNotificationResponse = {
        success: result.successCount > 0,
        sentCount: result.successCount,
        failedTokens: result.failedTokens,
      };

      const status = result.successCount > 0 ? 200 : 400;
      return Response.json(responseBody, { status });

    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      // Our controlled stage errors use a known prefix and carry NO secrets.
      // Any other failure is reported generically (never includes the raw
      // atob/key material) with a non-2xx status so the failure is not masked.
      console.error('[FCM] internal error:', message);
      const safeError = message.startsWith('Private key parsing')
        ? message
        : 'Internal server error';
      return Response.json(
        { success: false, error: safeError },
        { status: 500 }
      );
    }
  },
};