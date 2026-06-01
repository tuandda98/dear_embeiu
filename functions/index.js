const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();

// Daily sweep: validate every registered device token with a dry-run send
// (nothing is delivered) and delete the ones FCM reports as dead. Keeps the
// users/{uid}/devices subcollections free of stale tokens without waiting for
// a real photo-notification send to surface them.
exports.pruneDeadDevices = onSchedule(
  {schedule: "every 24 hours", timeZone: "Asia/Ho_Chi_Minh", region: "us-central1"},
  async () => {
    const snapshot = await db.collectionGroup("devices").get();
    const messaging = admin.messaging();
    let checked = 0;
    let alive = 0;
    let removed = 0;
    let kept = 0;

    for (const doc of snapshot.docs) {
      const token = `${doc.get("token") || ""}`.trim();
      if (!token) {
        await doc.ref.delete().catch(() => null);
        removed += 1;
        continue;
      }

      checked += 1;
      try {
        // dryRun = true -> FCM validates the token but delivers nothing.
        await messaging.send({token, data: {type: "token_health_check"}}, true);
        alive += 1;
      } catch (err) {
        const code = (err && err.code) ||
          (err && err.errorInfo && err.errorInfo.code) || "unknown";
        // Only delete on token-specific "dead" codes — never on generic
        // errors (which could indicate a transient/server issue, not a bad token).
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          await doc.ref.delete().catch(() => null);
          removed += 1;
        } else {
          kept += 1;
          logger.warn("Device token kept despite validation error.", {code});
        }
      }
    }

    logger.info("pruneDeadDevices finished.", {checked, alive, removed, kept});
  },
);

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

    // Gap B — build one message per device so each recipient gets the push in
    // the language THEIR device registered (falls back to Vietnamese). Sent via
    // sendEach (not multicast) because the notification text now varies by token.
    // TODO deploy: cần `firebase deploy --only functions` để áp dụng thay đổi này.
    const result = await sendToRecipientDevices(
      partnerIds,
      (languageCode) => buildPhotoNotificationText(languageCode, authorName, caption),
      {
        type: "photo_posted",
        coupleId,
        photoId,
        authorUserId,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Photo notification skipped because the partner has no active FCM tokens.", {
        coupleId,
        photoId,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Partner photo notification had delivery failures.", {
        coupleId,
        photoId,
        failures: result.failures,
        hasThirdPartyAuthError: result.failures.some(
          (failure) => failure.code === "messaging/third-party-auth-error",
        ),
      });
    }

    logger.info("Processed partner photo notification.", {
      coupleId,
      photoId,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  },
);

exports.notifyPartnerJoined = onDocumentUpdated(
  {document: "couples/{coupleId}", region: "us-central1"},
  async (event) => {
    const before = event.data && event.data.before && event.data.before.data();
    const after = event.data && event.data.after && event.data.after.data();
    if (!before || !after) {
      logger.warn("Partner-joined notification skipped because a snapshot is missing.");
      return;
    }

    const coupleId = `${event.params.coupleId || ""}`.trim();

    const beforeMembers = Array.isArray(before.memberIds)
      ? before.memberIds.filter((id) => typeof id === "string" && id.trim())
      : [];
    const afterMembers = Array.isArray(after.memberIds)
      ? after.memberIds.filter((id) => typeof id === "string" && id.trim())
      : [];

    // Guard — only fire on the exact "partner joined" transition: a couple that
    // had fewer than 2 members now has exactly 2 AND is active. Every other
    // update (cover photo change, leave/demote, name edit, etc.) returns early.
    const isPairingTransition =
      beforeMembers.length < 2 &&
      afterMembers.length === 2 &&
      `${after.status || ""}`.trim() === "active";
    if (!isPairingTransition) {
      return;
    }

    // joiner = uid present after but not before; recipients = the pre-existing
    // member(s) (the couple creator A). Bail safely on anomalous data.
    const joinerUid = afterMembers.find((id) => !beforeMembers.includes(id));
    const recipientIds = beforeMembers.filter((id) => id !== joinerUid);
    if (!joinerUid || recipientIds.length === 0) {
      logger.warn("Partner-joined notification skipped because joiner/recipients are unclear.", {
        coupleId,
        beforeMembers,
        afterMembers,
      });
      return;
    }

    // Joiner display name: prefer their user profile, then person2Name, then "Người ấy".
    let joinerName = "";
    try {
      const joinerSnap = await db.collection("users").doc(joinerUid).get();
      joinerName = `${(joinerSnap.exists && joinerSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load joiner profile for partner-joined notification.", {
        coupleId,
        joinerUid,
        message: err && err.message,
      });
    }
    if (!joinerName) {
      joinerName = `${after.person2Name || ""}`.trim();
    }
    joinerName = normalizeActorName(joinerName);

    const result = await sendToRecipientDevices(
      recipientIds,
      (languageCode) => buildPartnerJoinedText(languageCode, joinerName),
      {
        type: "partner_joined",
        coupleId,
        joinerUserId: joinerUid,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Partner-joined notification skipped because recipient has no active FCM tokens.", {
        coupleId,
        joinerUid,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Partner-joined notification had delivery failures.", {
        coupleId,
        joinerUid,
        failures: result.failures,
        hasThirdPartyAuthError: result.failures.some(
          (failure) => failure.code === "messaging/third-party-auth-error",
        ),
      });
    }

    logger.info("Processed partner-joined notification.", {
      coupleId,
      joinerUid,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  },
);

// Shared device-fan-out used by the partner-photo and partner-joined pushes.
// Collects every notifications-enabled device token for the recipients, builds
// one localized message per device (via `buildText(languageCode)`), sends them
// with sendEach, prunes dead tokens, and returns delivery stats + failures.
// `dataExtra` is merged into each message's data payload; `title`/`body` from
// buildText are also mirrored into data (kept consistent with the original
// photo-notification payload shape).
async function sendToRecipientDevices(recipientIds, buildText, dataExtra) {
  const deviceDocs = [];
  for (const recipientId of recipientIds) {
    const devicesSnapshot = await db
      .collection("users")
      .doc(recipientId)
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
        recipientId,
        platform: `${doc.get("platform") || "unknown"}`.trim().toLowerCase(),
        // Gap B — language of the recipient device, used to localize the push.
        languageCode: `${doc.get("languageCode") || ""}`.trim().toLowerCase(),
      });
    }
  }

  if (deviceDocs.length === 0) {
    return {deviceCount: 0, successCount: 0, failureCount: 0, failures: []};
  }

  const messages = deviceDocs.map((device) => {
    const {title, body} = buildText(device.languageCode);
    return {
      token: device.token,
      notification: {title, body},
      data: {
        ...dataExtra,
        title,
        body,
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
    };
  });

  const response = await admin.messaging().sendEach(messages);

  const invalidRefs = [];
  const failures = [];
  response.responses.forEach((res, index) => {
    if (res.success) {
      return;
    }

    const code = res.error && res.error.code;
    failures.push({
      recipientId: deviceDocs[index].recipientId,
      platform: deviceDocs[index].platform,
      code: code || "unknown",
      message: res.error && res.error.message,
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

  return {
    deviceCount: deviceDocs.length,
    successCount: response.successCount,
    failureCount: response.failureCount,
    failures,
  };
}

// Callable that fully erases the signed-in user's account. It runs with admin
// privileges so it can remove the things the client is forbidden to delete
// directly under the Firestore security rules (`users/{uid}` and
// `invite_codes/{code}` are both `allow delete: if false`) and can delete the
// Auth user without a recent-login challenge. Required by the App Store
// (5.1.1(v)) and Google Play account-deletion policies.
exports.deleteAccount = onCall(
  {region: "us-central1"},
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Bạn cần đăng nhập để xoá tài khoản.",
      );
    }

    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    const userData = userSnap.exists ? userSnap.data() || {} : {};
    const coupleId = `${userData.coupleId || ""}`.trim();
    const inviteCode = `${userData.inviteCode || ""}`.trim().toUpperCase();

    // 1) Detach from / tear down the couple before the user doc disappears.
    if (coupleId) {
      try {
        await handleCoupleOnAccountDeletion(coupleId, uid);
      } catch (err) {
        logger.error("Couple teardown failed during account deletion.", {
          uid,
          coupleId,
          message: err && err.message,
        });
        throw new HttpsError("internal", "Không thể xoá dữ liệu cặp đôi. Vui lòng thử lại.");
      }
    }

    // 2) Device tokens (FCM) for this user.
    const devicesSnap = await userRef.collection("devices").get();
    await Promise.all(devicesSnap.docs.map((doc) => doc.ref.delete().catch(() => null)));

    // 3) The invite_code pointer — only if it still points at this user, so we
    //    never clobber a code that has since been reassigned.
    if (inviteCode) {
      const inviteRef = db.collection("invite_codes").doc(inviteCode);
      const inviteSnap = await inviteRef.get();
      if (inviteSnap.exists && `${inviteSnap.get("userId") || ""}`.trim() === uid) {
        await inviteRef.delete().catch(() => null);
      }
    }

    // 4) The user profile document.
    await userRef.delete().catch(() => null);

    // 5) The Auth user itself (no recent-login requirement on the admin SDK).
    try {
      await admin.auth().deleteUser(uid);
    } catch (err) {
      const code = (err && err.code) || "unknown";
      // auth/user-not-found means it's already gone — treat as success.
      if (code !== "auth/user-not-found") {
        logger.error("Failed to delete Auth user during account deletion.", {uid, code});
        throw new HttpsError("internal", "Không thể xoá tài khoản đăng nhập. Vui lòng thử lại.");
      }
    }

    logger.info("Account deleted.", {uid, coupleId: coupleId || null});
    return {success: true};
  },
);

// Mirror of the client-side leaveCouple semantics: if the leaving user is the
// only remaining member, the couple (with all its photos + Storage objects) is
// destroyed; otherwise the partner is kept and the couple is demoted back to
// the "waiting_partner" state.
async function handleCoupleOnAccountDeletion(coupleId, uid) {
  const coupleRef = db.collection("couples").doc(coupleId);
  const coupleSnap = await coupleRef.get();
  if (!coupleSnap.exists) {
    return;
  }

  const data = coupleSnap.data() || {};
  const memberIds = Array.isArray(data.memberIds) ? data.memberIds : [];
  const remaining = memberIds.filter(
    (id) => typeof id === "string" && id.trim() && id !== uid,
  );

  if (remaining.length === 0) {
    await deleteCoupleCompletely(coupleRef, data);
    return;
  }

  await coupleRef.set(
    {
      memberIds: remaining,
      memberCount: remaining.length,
      status: "waiting_partner",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function deleteCoupleCompletely(coupleRef, coupleData) {
  const photosSnap = await coupleRef.collection("photos").get();
  const tasks = [];

  for (const photoDoc of photosSnap.docs) {
    const storagePath = `${photoDoc.get("storagePath") || ""}`.trim();
    if (storagePath) {
      tasks.push(deleteStorageObject(storagePath));
    }
    tasks.push(photoDoc.ref.delete().catch(() => null));
  }

  const coverPath = `${(coupleData && coupleData.couplePhotoStoragePath) || ""}`.trim();
  if (coverPath) {
    tasks.push(deleteStorageObject(coverPath));
  }

  await Promise.all(tasks);

  // Sweep the whole prefix too, in case any object was orphaned from its doc.
  await deleteStoragePrefix(`couple_photos/${coupleRef.id}/`);

  await coupleRef.delete().catch(() => null);
}

async function deleteStorageObject(path) {
  try {
    await admin.storage().bucket().file(path).delete();
  } catch (err) {
    if (!err || err.code !== 404) {
      logger.warn("Failed to delete Storage object during account deletion.", {
        path,
        code: err && err.code,
      });
    }
  }
}

async function deleteStoragePrefix(prefix) {
  try {
    await admin.storage().bucket().deleteFiles({prefix});
  } catch (err) {
    logger.warn("Failed to sweep Storage prefix during account deletion.", {
      prefix,
      message: err && err.message,
    });
  }
}

function normalizeActorName(value) {
  const normalized = `${value || ""}`.trim();
  return normalized || "Người ấy";
}

// Gap B — localized copy for the partner-photo push, keyed by the recipient
// device's languageCode. Unknown/missing codes fall back to Vietnamese.
const PHOTO_NOTIFICATION_COPY = {
  vi: {
    title: (author) => `${author} vừa đăng ảnh mới 💞`,
    fallbackBody: "Mở app để xem khoảnh khắc mới của hai bạn nhé.",
  },
  en: {
    title: (author) => `${author} just shared a new photo 💞`,
    fallbackBody: "Open the app to see your latest moment together.",
  },
};

function buildPhotoNotificationText(languageCode, authorName, caption) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = PHOTO_NOTIFICATION_COPY[code] || PHOTO_NOTIFICATION_COPY.vi;
  const trimmedCaption = `${caption || ""}`.trim();
  return {
    title: copy.title(authorName),
    body: trimmedCaption ? truncateText(trimmedCaption, 120) : copy.fallbackBody,
  };
}

// Localized copy for the partner-joined push, keyed by the recipient device's
// languageCode. Unknown/missing codes fall back to Vietnamese.
const PARTNER_JOINED_COPY = {
  vi: {
    title: (name) => `${name} đã ghép đôi cùng bạn 💞`,
    body: "Hai bạn đã kết nối rồi — cùng bắt đầu lưu kỷ niệm nhé!",
  },
  en: {
    title: (name) => `${name} just paired up with you 💞`,
    body: "You're connected now — start saving memories together!",
  },
};

function buildPartnerJoinedText(languageCode, joinerName) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = PARTNER_JOINED_COPY[code] || PARTNER_JOINED_COPY.vi;
  return {
    title: copy.title(joinerName),
    body: copy.body,
  };
}

function truncateText(value, maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, maxLength - 1).trimEnd()}…`;
}

