const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Stripe = require("stripe");

admin.initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const db = admin.firestore();
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return request.auth.uid;
}

function createStripeClient() {
  return new Stripe(stripeSecretKey.value());
}

exports.createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const userId = requireAuth(request);
    const amount = Number(request.data?.amount || 0);
    const currency = request.data?.currency || "myr";
    const metadata = request.data?.metadata || {};

    if (!Number.isFinite(amount) || amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "Amount must be a positive integer in cents."
      );
    }

    const stripe = createStripeClient();
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        userId,
        ...metadata,
      },
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  }
);

exports.confirmPayment = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    requireAuth(request);
    const paymentIntentId = request.data?.paymentIntentId;

    if (!paymentIntentId) {
      throw new HttpsError(
        "invalid-argument",
        "paymentIntentId is required."
      );
    }

    const stripe = createStripeClient();
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    return {
      paymentIntentId: paymentIntent.id,
      status: paymentIntent.status,
    };
  }
);

exports.saveOrderAfterPayment = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const userId = requireAuth(request);
    const paymentIntentId = request.data?.paymentIntentId;
    const order = request.data?.order;

    if (!paymentIntentId || !order) {
      throw new HttpsError(
        "invalid-argument",
        "paymentIntentId and order are required."
      );
    }

    if (!Array.isArray(order.items) || order.items.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Order items are required."
      );
    }

    const stripe = createStripeClient();
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status !== "succeeded") {
      throw new HttpsError(
        "failed-precondition",
        "Payment has not completed successfully."
      );
    }

    if (
      paymentIntent.metadata?.userId &&
      paymentIntent.metadata.userId !== userId
    ) {
      throw new HttpsError(
        "permission-denied",
        "This payment intent does not belong to the current user."
      );
    }

    const existingOrder = await db
      .collection("orders")
      .where("stripePaymentId", "==", paymentIntentId)
      .limit(1)
      .get();

    if (!existingOrder.empty) {
      return {
        orderId: existingOrder.docs[0].id,
        order: existingOrder.docs[0].data(),
      };
    }

    const orderRef = db.collection("orders").doc();

    await db.runTransaction(async (transaction) => {
      let computedSubtotal = 0;

      for (const item of order.items) {
        const quantity = Number(item.quantity || 0);
        const price = Number(item.price || 0);
        const shoeId = item.shoeId;

        if (!shoeId || quantity <= 0 || price < 0) {
          throw new HttpsError(
            "invalid-argument",
            "Each order item must include shoeId, quantity, and price."
          );
        }

        computedSubtotal += quantity * price;

        const productRef = db.collection("products").doc(shoeId);
        const productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            `Product ${shoeId} no longer exists.`
          );
        }

        const currentStock = Number(productSnapshot.data().stock || 0);
        if (currentStock < quantity) {
          throw new HttpsError(
            "failed-precondition",
            `${productSnapshot.data().name || "Product"} is out of stock.`
          );
        }

        transaction.update(productRef, {
          stock: currentStock - quantity,
        });
      }

      transaction.set(orderRef, {
        orderId: orderRef.id,
        userId,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        deliveryAddress: order.deliveryAddress,
        items: order.items,
        subtotal: Number(order.subtotal || computedSubtotal),
        shippingFee: Number(order.shippingFee || 0),
        totalPrice: Number(order.totalPrice || 0),
        paymentMethod: order.paymentMethod || "Stripe",
        paymentStatus: "paid",
        stripePaymentId: paymentIntent.id,
        orderStatus: order.orderStatus || "Processing",
        orderDate: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    const cartSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("cart")
      .get();

    if (!cartSnapshot.empty) {
      const batch = db.batch();
      cartSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    const savedOrderSnapshot = await orderRef.get();
    return {
      orderId: orderRef.id,
      order: savedOrderSnapshot.data(),
    };
  }
);
