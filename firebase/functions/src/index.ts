import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

/**
 * Records a product view.
 *
 * - Requires an authenticated caller (enforced via request.auth).
 * - Accepts only a productId; the increment amount is fixed server-side,
 *   so clients can never specify or forge an arbitrary delta.
 * - Verifies the product exists before touching it.
 * - Increments `views` atomically via FieldValue.increment(1).
 * - Cannot modify any other product field; seller/admin ownership
 *   rules in firestore.rules remain the only other update path.
 */
export const incrementProductViews = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const productId = request.data?.productId;

  if (
    typeof productId !== "string" ||
    productId.length === 0 ||
    productId.length > 450 ||
    productId.includes("/")
  ) {
    throw new HttpsError("invalid-argument", "Invalid product ID.");
  }

  const productRef = getFirestore().collection("products").doc(productId);

  const snapshot = await productRef.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Product not found.");
  }

  await productRef.update({ views: FieldValue.increment(1) });

  return { ok: true };
});
