const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();

exports.sendPartnerPhotoNotification = onDocumentCreated(
  "couples/{coupleId}/photos/{photoId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Photo notification skipped because snapshot is missing.");
      return;
    }

    const photo = snapshot.data() || {};
    const coupleId = `${photo.coupleId || event.params.coupleId || ""}`.trim();
    const photoId = `${event.params.photoId || snapshot.id || ""}`.trim();
    const authorUserId = `${photo.authorUserId || ""}`.trim();
    const authorName = normalizeActorName(photo.authorName);
    const caption = `${photo.caption || ""}`.trim();

    if (!coupleId || !photoId || !authorUserId) {
      logger.warn("Photo notification skipped because required fields are missing.", {
        coupleId,
        photoId,
        authorUserId,
      });
      return;
    }

    const coupleSnapshot = await db.collection("couples").doc(coupleId).get();
    if (!coupleSnapshot.exists) {
      logger.warn("Photo notification skipped because couple document was not found.", {
        coupleId,
      });
      return;
    }

    const memberIds = Array.isArray(coupleSnapshot.get("memberIds"))
      ? coupleSnapshot.get("memberIds")
      : [];
    const partnerIds = memberIds.filter(
      (memberId) => typeof memberId === "string" && memberId.trim() && memberId !== authorUserId,
    );

    if (partnerIds.length === 0) {
      logger.info("Photo notification skipped because there is no partner device to notify yet.", {
        coupleId,
        photoId,
      });
      return;
    }

    const deviceDocs = [];
    for (const partnerId of partnerIds) {
      const devicesSnapshot = await db
        .collection("users")
        .doc(partnerId)
        .collection("devices")
        .where("notificationsEnabled", "==", true)
        .get();

      for (const doc of devicesSnapshot.docs) {
        const token = `${doc.get("token") || ""}`.trim();
        if (!token) {
          continue;
        }

        deviceDocs.push({
          token,
          ref: doc.ref,
          partnerId,
          platform: `${doc.get("platform") || "unknown"}`.trim().toLowerCase(),
        });
      }
    }

    if (deviceDocs.length === 0) {
      logger.info("Photo notification skipped because the partner has no active FCM tokens.", {
        coupleId,
        photoId,
      });
      return;
    }

    const title = `${authorName} vừa đăng ảnh mới 💞`;
    const body = caption
      ? truncateText(caption, 120)
      : "Mở app để xem khoảnh khắc mới của hai bạn nhé.";

    const response = await admin.messaging().sendEachForMulticast({
      tokens: deviceDocs.map((entry) => entry.token),
      notification: {
        title,
        body,
      },
      data: {
        type: "photo_posted",
        title,
        body,
        coupleId,
        photoId,
        authorUserId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "partner_photo_updates",
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    const invalidRefs = [];
    const failures = [];
    response.responses.forEach((result, index) => {
      if (result.success) {
        return;
      }

      const code = result.error && result.error.code;
      failures.push({
        partnerId: deviceDocs[index].partnerId,
        platform: deviceDocs[index].platform,
        code: code || "unknown",
        message: result.error && result.error.message,
      });

      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalidRefs.push(deviceDocs[index].ref);
      }
    });

    if (invalidRefs.length > 0) {
      await Promise.all(invalidRefs.map((ref) => ref.delete().catch(() => null)));
    }

    if (failures.length > 0) {
      logger.warn("Partner photo notification had delivery failures.", {
        coupleId,
        photoId,
        failures,
        hasThirdPartyAuthError: failures.some(
          (failure) => failure.code === "messaging/third-party-auth-error",
        ),
      });
    }

    logger.info("Processed partner photo notification.", {
      coupleId,
      photoId,
      attemptedTokens: deviceDocs.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  },
);

function normalizeActorName(value) {
  const normalized = `${value || ""}`.trim();
  return normalized || "Người ấy";
}

function truncateText(value, maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, maxLength - 1).trimEnd()}…`;
}

