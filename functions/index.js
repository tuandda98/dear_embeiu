const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {onDocumentCreated, onDocumentUpdated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {buildVerificationEmail} = require("./emails/verification_email");

// Resend API key for the custom branded verification email (feature auth —
// "Cách B"). Set before deploy:
//   firebase functions:secrets:set RESEND_API_KEY --project <dev|prod>
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

// Sender identity — domain must be verified on Resend before sending works.
const VERIFICATION_EMAIL_FROM = "Dear Embeiu <noreply@dearembeiu.com>";

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

exports.notifyLoveNote = onDocumentWritten(
  {document: "couples/{coupleId}/notes/{noteId}", region: "us-central1"},
  async (event) => {
    const after = event.data && event.data.after && event.data.after.exists ?
      event.data.after.data() : null;
    // Skip deletions (no `after`).
    if (!after) {
      return;
    }

    const before = event.data && event.data.before && event.data.before.exists ?
      event.data.before.data() : null;

    const coupleId = `${event.params.coupleId || ""}`.trim();
    // noteId === the author's uid by convention.
    const authorUserId = `${event.params.noteId || ""}`.trim();
    const text = `${after.text || ""}`.trim();
    const beforeText = `${(before && before.text) || ""}`.trim();

    // Skip empty notes and no-op writes (text unchanged, e.g. a metadata-only
    // merge or a re-save with the same content).
    if (!text || text === beforeText) {
      return;
    }

    if (!coupleId || !authorUserId) {
      logger.warn("Love-note notification skipped because required fields are missing.", {
        coupleId,
        authorUserId,
      });
      return;
    }

    const coupleSnapshot = await db.collection("couples").doc(coupleId).get();
    if (!coupleSnapshot.exists) {
      logger.warn("Love-note notification skipped because couple document was not found.", {
        coupleId,
      });
      return;
    }

    const memberIds = Array.isArray(coupleSnapshot.get("memberIds")) ?
      coupleSnapshot.get("memberIds") : [];
    const recipientIds = memberIds.filter(
      (memberId) => typeof memberId === "string" && memberId.trim() && memberId !== authorUserId,
    );

    if (recipientIds.length === 0) {
      logger.info("Love-note notification skipped because there is no partner to notify yet.", {
        coupleId,
      });
      return;
    }

    // Author display name from their user profile (fallback "Người ấy").
    let authorName = "";
    try {
      const authorSnap = await db.collection("users").doc(authorUserId).get();
      authorName = `${(authorSnap.exists && authorSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load author profile for love-note notification.", {
        coupleId,
        authorUserId,
        message: err && err.message,
      });
    }
    authorName = normalizeActorName(authorName);

    const result = await sendToRecipientDevices(
      recipientIds,
      (languageCode) => buildLoveNoteText(languageCode, authorName, text),
      {
        type: "love_note",
        coupleId,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Love-note notification skipped because recipient has no active FCM tokens.", {
        coupleId,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Love-note notification had delivery failures.", {
        coupleId,
        failures: result.failures,
      });
    }

    logger.info("Processed love-note notification.", {
      coupleId,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  },
);

// Daily question (feature #5): when a member submits their answer for the day,
// notify the partner that today's question has been answered (a nudge to answer
// and unlock the reveal). The reveal itself is client-side; this is just a ping.
exports.notifyDailyAnswer = onDocumentCreated(
  {document: "couples/{coupleId}/dailyAnswers/{date}/responses/{uid}", region: "us-central1"},
  async (event) => {
    const coupleId = `${event.params.coupleId || ""}`.trim();
    // The responses doc id === the answering member's uid by convention.
    const authorUserId = `${event.params.uid || ""}`.trim();

    if (!coupleId || !authorUserId) {
      logger.warn("Daily-answer notification skipped because required fields are missing.", {
        coupleId,
        authorUserId,
      });
      return;
    }

    const coupleSnapshot = await db.collection("couples").doc(coupleId).get();
    if (!coupleSnapshot.exists) {
      logger.warn("Daily-answer notification skipped because couple document was not found.", {
        coupleId,
      });
      return;
    }

    const memberIds = Array.isArray(coupleSnapshot.get("memberIds")) ?
      coupleSnapshot.get("memberIds") : [];
    const recipientIds = memberIds.filter(
      (memberId) => typeof memberId === "string" && memberId.trim() && memberId !== authorUserId,
    );

    if (recipientIds.length === 0) {
      logger.info("Daily-answer notification skipped because there is no partner to notify yet.", {
        coupleId,
      });
      return;
    }

    // Answering member's display name (fallback "Người ấy").
    let authorName = "";
    try {
      const authorSnap = await db.collection("users").doc(authorUserId).get();
      authorName = `${(authorSnap.exists && authorSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load author profile for daily-answer notification.", {
        coupleId,
        authorUserId,
        message: err && err.message,
      });
    }
    authorName = normalizeActorName(authorName);

    const result = await sendToRecipientDevices(
      recipientIds,
      (languageCode) => buildDailyAnswerText(languageCode, authorName),
      {
        type: "daily_question",
        coupleId,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Daily-answer notification skipped because recipient has no active FCM tokens.", {
        coupleId,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Daily-answer notification had delivery failures.", {
        coupleId,
        failures: result.failures,
      });
    }

    logger.info("Processed daily-answer notification.", {
      coupleId,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  },
);

// Reactions (feature: reactions ❤️): when a member reacts to a photo, notify the
// photo's author (the partner) that their photo got a reaction. Fires ONLY on
// the initial create (onDocumentCreated) — NOT on emoji changes — so swapping
// reactions never spams a second push (PO "debounce push" decision). When the
// reactor is the photo's own author, no push is sent (PO decision D3).
exports.notifyPhotoReaction = onDocumentCreated(
  {document: "couples/{coupleId}/photos/{photoId}/reactions/{uid}", region: "us-central1"},
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Reaction notification skipped because snapshot is missing.");
      return;
    }

    const reaction = snapshot.data() || {};
    const coupleId = `${event.params.coupleId || ""}`.trim();
    const photoId = `${event.params.photoId || ""}`.trim();
    // The reactions doc id === the reacting member's uid by convention.
    const reactorUid = `${event.params.uid || ""}`.trim();
    const emoji = `${reaction.emoji || "❤️"}`.trim() || "❤️";

    if (!coupleId || !photoId || !reactorUid) {
      logger.warn("Reaction notification skipped because required fields are missing.", {
        coupleId,
        photoId,
        reactorUid,
      });
      return;
    }

    // Look up the photo to find its author (the recipient of the push).
    const photoSnap = await db
      .collection("couples").doc(coupleId)
      .collection("photos").doc(photoId)
      .get();
    if (!photoSnap.exists) {
      logger.info("Reaction notification skipped because the photo no longer exists.", {
        coupleId,
        photoId,
      });
      return;
    }

    const authorUserId = `${photoSnap.get("authorUserId") || ""}`.trim();
    if (!authorUserId) {
      logger.warn("Reaction notification skipped because the photo has no author.", {
        coupleId,
        photoId,
      });
      return;
    }

    // D3 — never push when someone reacts to their OWN photo.
    if (reactorUid === authorUserId) {
      return;
    }

    // Reacting member's display name (fallback "Người ấy").
    let reactorName = "";
    try {
      const reactorSnap = await db.collection("users").doc(reactorUid).get();
      reactorName = `${(reactorSnap.exists && reactorSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load reactor profile for reaction notification.", {
        coupleId,
        reactorUid,
        message: err && err.message,
      });
    }
    reactorName = normalizeActorName(reactorName);

    const result = await sendToRecipientDevices(
      [authorUserId],
      (languageCode) => buildReactionText(languageCode, reactorName, emoji),
      {
        type: "photo_reaction",
        coupleId,
        photoId,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Reaction notification skipped because the author has no active FCM tokens.", {
        coupleId,
        photoId,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Reaction notification had delivery failures.", {
        coupleId,
        photoId,
        failures: result.failures,
      });
    }

    logger.info("Processed reaction notification.", {
      coupleId,
      photoId,
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

// Custom branded verification email (feature auth — "Cách B"). Replaces the
// default `FirebaseUser.sendEmailVerification()` so the user receives the
// on-brand HTML email built in emails/verification_email.js, delivered through
// Resend, instead of Firebase's plain template. The VERIFICATION MECHANISM is
// unchanged — we generate the same Firebase verification link (oobCode) and the
// app still auto-polls `reload()`; only the delivery channel differs.
exports.sendCustomVerificationEmail = onCall(
  {region: "us-central1", secrets: [RESEND_API_KEY]},
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Bạn cần đăng nhập để gửi email xác thực.",
      );
    }

    // Pull the authoritative email/name/verified state from the Auth record
    // (not from client-supplied data) so we never email an attacker-chosen
    // address or skip the already-verified check.
    let userRecord;
    try {
      userRecord = await admin.auth().getUser(uid);
    } catch (err) {
      logger.error("Custom verification email: could not load Auth user.", {
        uid,
        message: err && err.message,
      });
      throw new HttpsError("internal", "Không thể đọc thông tin tài khoản.");
    }

    const email = `${userRecord.email || ""}`.trim();
    if (!email) {
      throw new HttpsError("failed-precondition", "Tài khoản chưa có email.");
    }

    // Already verified — nothing to send. Tell the client so it can skip.
    if (userRecord.emailVerified === true) {
      return {skipped: true};
    }

    // Generate the standard Firebase verification link. We intentionally DON'T
    // pass actionCodeSettings so Firebase uses the default action URL, avoiding
    // the need to authorize a custom continue-domain.
    let verifyUrl;
    try {
      verifyUrl = await admin.auth().generateEmailVerificationLink(email);
    } catch (err) {
      logger.error("Custom verification email: link generation failed.", {
        uid,
        message: err && err.message,
      });
      throw new HttpsError("internal", "Không thể tạo liên kết xác thực.");
    }

    // Language for the email copy comes from the client device locale (same
    // pattern as the push copy), fallback vi.
    const lang = `${(request.data && request.data.languageCode) || ""}`
      .trim()
      .toLowerCase() || "vi";
    const name = `${userRecord.displayName || ""}`.trim();

    const {subject, html} = buildVerificationEmail({name, verifyUrl, lang});

    // Send via the Resend HTTP API (Node 20 has global fetch — no SDK dep).
    let response;
    try {
      response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${RESEND_API_KEY.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: VERIFICATION_EMAIL_FROM,
          to: [email],
          subject,
          html,
        }),
      });
    } catch (err) {
      logger.error("Custom verification email: Resend request threw.", {
        uid,
        message: err && err.message,
      });
      throw new HttpsError("internal", "Không gửi được email xác thực.");
    }

    if (!response.ok) {
      const detail = await response.text().catch(() => "");
      logger.error("Custom verification email: Resend returned an error.", {
        uid,
        status: response.status,
        detail: detail.slice(0, 500),
      });
      // Surface as a failure so the client can show "Resend" / retry.
      throw new HttpsError("internal", "Không gửi được email xác thực.");
    }

    logger.info("Custom verification email sent.", {uid, lang});
    return {sent: true};
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
    // Reactions (feature: reactions ❤️) live in a subcollection under each
    // photo, so deleting the photo doc alone leaves them orphaned. recursiveDelete
    // the reactions first, then delete the photo doc itself.
    tasks.push(
      db.recursiveDelete(photoDoc.ref.collection("reactions"))
        .catch((err) => {
          logger.warn("Failed to recursively delete photo reactions during couple teardown.", {
            coupleId: coupleRef.id,
            photoId: photoDoc.id,
            message: err && err.message,
          });
          return null;
        })
        .then(() => photoDoc.ref.delete().catch(() => null)),
    );
  }

  // Love notes subcollection (feature #4): one doc per member, no Storage.
  const notesSnap = await coupleRef.collection("notes").get();
  for (const noteDoc of notesSnap.docs) {
    tasks.push(noteDoc.ref.delete().catch(() => null));
  }

  // Daily question answers (feature #5): nested subcollection
  // (dailyAnswers/{date}/responses/{uid}). recursiveDelete handles the nesting
  // and any phantom parent docs, so use it instead of a flat get().delete().
  tasks.push(
    db.recursiveDelete(coupleRef.collection("dailyAnswers")).catch((err) => {
      logger.warn("Failed to recursively delete dailyAnswers during couple teardown.", {
        coupleId: coupleRef.id,
        message: err && err.message,
      });
      return null;
    }),
  );

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

// Localized copy for the love-note push (feature #4), keyed by the recipient
// device's languageCode. Unknown/missing codes fall back to Vietnamese.
const LOVE_NOTE_COPY = {
  vi: {
    title: (author) => `${author} vừa để lại lời nhắn 💞`,
  },
  en: {
    title: (name) => `${name} left you a love note 💞`,
  },
};

function buildLoveNoteText(languageCode, authorName, noteText) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = LOVE_NOTE_COPY[code] || LOVE_NOTE_COPY.vi;
  return {
    title: copy.title(authorName),
    body: truncateText(`${noteText || ""}`.trim(), 120),
  };
}

// Localized copy for the daily-question push (feature #5), keyed by the
// recipient device's languageCode. Unknown/missing codes fall back to
// Vietnamese. Body is a gentle nudge to answer and unlock the reveal.
const DAILY_QUESTION_COPY = {
  vi: {
    title: (author) => `${author} đã trả lời câu hỏi hôm nay 💞`,
    body: "Trả lời câu hỏi của bạn để mở khoá câu trả lời của người ấy nhé.",
  },
  en: {
    title: (name) => `${name} answered today's question 💞`,
    body: "Answer yours to unlock your partner's reply.",
  },
};

function buildDailyAnswerText(languageCode, authorName) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = DAILY_QUESTION_COPY[code] || DAILY_QUESTION_COPY.vi;
  return {
    title: copy.title(authorName),
    body: copy.body,
  };
}

// Localized copy for the reaction push (feature: reactions ❤️), keyed by the
// recipient device's languageCode. Unknown/missing codes fall back to
// Vietnamese. The reactor's chosen emoji is baked into the body.
const REACTION_COPY = {
  vi: {
    title: "Dear Embeiu",
    body: (name, emoji) => `${name} đã thả ${emoji} vào ảnh của bạn`,
  },
  en: {
    title: "Dear Embeiu",
    body: (name, emoji) => `${name} reacted ${emoji} to your photo`,
  },
};

function buildReactionText(languageCode, reactorName, emoji) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = REACTION_COPY[code] || REACTION_COPY.vi;
  return {
    title: copy.title,
    body: copy.body(reactorName, `${emoji || "❤️"}`.trim() || "❤️"),
  };
}

function truncateText(value, maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, maxLength - 1).trimEnd()}…`;
}

