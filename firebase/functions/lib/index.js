"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.incrementProductViews = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
(0, app_1.initializeApp)();
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
exports.incrementProductViews = (0, https_1.onCall)(async (request) => {
    var _a;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "You must be signed in.");
    }
    const productId = (_a = request.data) === null || _a === void 0 ? void 0 : _a.productId;
    if (typeof productId !== "string" ||
        productId.length === 0 ||
        productId.length > 450 ||
        productId.includes("/")) {
        throw new https_1.HttpsError("invalid-argument", "Invalid product ID.");
    }
    const productRef = (0, firestore_1.getFirestore)().collection("products").doc(productId);
    const snapshot = await productRef.get();
    if (!snapshot.exists) {
        throw new https_1.HttpsError("not-found", "Product not found.");
    }
    await productRef.update({ views: firestore_1.FieldValue.increment(1) });
    return { ok: true };
});
//# sourceMappingURL=index.js.map