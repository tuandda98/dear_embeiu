const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {onDocumentCreated, onDocumentUpdated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {buildVerificationEmail} = require("./emails/verification_email");
const {buildPasswordResetEmail} = require("./emails/password_reset_email");

// Resend API key — used by both sendCustomVerificationEmail and
// sendCustomPasswordResetEmail. Set before deploy:
//   firebase functions:secrets:set RESEND_API_KEY --project <dev|prod>
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

// Sender identity — domain must be verified on Resend before sending works.
const VERIFICATION_EMAIL_FROM = "Dear Embeiu <noreply@dearembeiu.com>";

// On-brand email action handler (feature auth, 2026-06-20). Firebase's default
// action page is replaced by our hosted page (docs/auth-action.html on GitHub
// Pages) which applies the oobCode via the identitytoolkit REST API and shows a
// Sunset Romance UI + "open app" deep link. We rewrite the host/path of the
// Firebase-generated action link to point here. This avoids the flaky Console
// "Customize action URL" setting and works identically on dev + prod.
const AUTH_ACTION_PAGE = "https://dearembeiu.com/auth-action.html";

// Repoint a Firebase action link (verify-email / password-reset) at our hosted
// handler page, keeping all query params (mode/oobCode/apiKey/continueUrl).
// `lang` is forced so the page copy matches the email language. Fail-open: on
// any parse error — or a link missing oobCode/apiKey — return the original link
// so verification still works through Firebase's default page.
function rewriteActionLink(firebaseLink, lang) {
  try {
    const src = new URL(firebaseLink);
    const target = new URL(AUTH_ACTION_PAGE);
    target.search = src.search;
    if (lang) {
      target.searchParams.set("lang", lang);
    }
    if (!target.searchParams.get("oobCode") ||
        !target.searchParams.get("apiKey")) {
      return firebaseLink;
    }
    return target.toString();
  } catch (_) {
    return firebaseLink;
  }
}

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
    await writeInboxNotifications(partnerIds, {
      type: "photo_posted",
      coupleId,
      actorUserId: authorUserId,
      actorName: authorName,
      photoId,
      caption: truncateText(caption, 140),
    });

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

    // Status parity heal: the client join transaction only writes the JOINER's
    // user doc (status='in_couple'); the creator (A, here a recipient) is never
    // touched, so without this their users/{A}.status lingers at the stale
    // 'waiting_partner' even though the couple is now active. The admin SDK
    // bypasses the per-user rules, so we authoritatively flip every pre-existing
    // member to 'in_couple'. Best-effort per doc — a notification must still go
    // out even if a heal write fails.
    await Promise.all(
      recipientIds.map((uid) =>
        db
          .collection("users")
          .doc(uid)
          .set(
            {
              status: "in_couple",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true},
          )
          .catch((err) => {
            logger.warn("Could not heal member status to in_couple on partner join.", {
              coupleId,
              uid,
              message: err && err.message,
            });
          }),
      ),
    );

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

    await writeInboxNotifications(recipientIds, {
      type: "partner_joined",
      coupleId,
      actorUserId: joinerUid,
      actorName: joinerName,
    });

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

exports.notifyPartnerLeft = onDocumentUpdated(
  {document: "couples/{coupleId}", region: "us-central1"},
  async (event) => {
    const before = event.data && event.data.before && event.data.before.data();
    const after = event.data && event.data.after && event.data.after.data();
    if (!before || !after) {
      logger.warn("Partner-left notification skipped because a snapshot is missing.");
      return;
    }

    const coupleId = `${event.params.coupleId || ""}`.trim();

    const beforeMembers = Array.isArray(before.memberIds)
      ? before.memberIds.filter((id) => typeof id === "string" && id.trim())
      : [];
    const afterMembers = Array.isArray(after.memberIds)
      ? after.memberIds.filter((id) => typeof id === "string" && id.trim())
      : [];

    // Guard — fire only on the exact "partner left" transition: a 2-member
    // active couple demoted to a single waiting member. Every other update
    // (join, cover photo change, name edit) returns early. A sole member
    // leaving deletes the couple (onDocumentDeleted), so it never reaches here.
    const isLeaveTransition =
      beforeMembers.length === 2 &&
      afterMembers.length === 1 &&
      `${after.status || ""}`.trim() === "waiting_partner";
    if (!isLeaveTransition) {
      return;
    }

    // leaver = uid present before but not after; recipient = the member who stayed.
    const leaverUid = beforeMembers.find((id) => !afterMembers.includes(id));
    const recipientIds = afterMembers;
    if (!leaverUid || recipientIds.length === 0) {
      logger.warn("Partner-left notification skipped because leaver/recipient are unclear.", {
        coupleId,
        beforeMembers,
        afterMembers,
      });
      return;
    }

    // Status parity heal (symmetric to notifyPartnerJoined): when a partner
    // leaves, the client leave write can only touch the LEAVER's own user doc —
    // the remaining member (B) is left stale at 'in_couple' even though the
    // couple demoted back to 'waiting_partner' (the client's best-effort
    // cross-user write to B is denied by the per-user rules). The admin SDK
    // bypasses those rules, so we authoritatively reset every remaining member
    // to 'waiting_partner' so they can accept a new partner join. Best-effort
    // per doc — the notification must still go out even if a heal write fails.
    await Promise.all(
      recipientIds.map((uid) =>
        db
          .collection("users")
          .doc(uid)
          .set(
            {
              status: "waiting_partner",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true},
          )
          .catch((err) => {
            logger.warn("Could not heal member status to waiting_partner on partner left.", {
              coupleId,
              uid,
              message: err && err.message,
            });
          }),
      ),
    );

    // Leaver display name: prefer their user profile (still exists — they only
    // left the couple), fall back to "Người ấy" via normalizeActorName.
    let leaverName = "";
    try {
      const leaverSnap = await db.collection("users").doc(leaverUid).get();
      leaverName = `${(leaverSnap.exists && leaverSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load leaver profile for partner-left notification.", {
        coupleId,
        leaverUid,
        message: err && err.message,
      });
    }
    leaverName = normalizeActorName(leaverName);

    await writeInboxNotifications(recipientIds, {
      type: "partner_left",
      coupleId,
      actorUserId: leaverUid,
      actorName: leaverName,
    });

    const result = await sendToRecipientDevices(
      recipientIds,
      (languageCode) => buildPartnerLeftText(languageCode, leaverName),
      {
        type: "partner_left",
        coupleId,
        leaverUserId: leaverUid,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Partner-left notification skipped because recipient has no active FCM tokens.", {
        coupleId,
        leaverUid,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Partner-left notification had delivery failures.", {
        coupleId,
        leaverUid,
        failures: result.failures,
      });
    }

    logger.info("Processed partner-left notification.", {
      coupleId,
      leaverUid,
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

    await writeInboxNotifications(recipientIds, {
      type: "love_note",
      coupleId,
      actorUserId: authorUserId,
      actorName: authorName,
      noteExcerpt: truncateText(text, 140),
    });

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

// Couple chat (feature chat, D4): when a member sends a chat message, ping the
// partner. PRIVACY: the push (and the inbox record) carries NO message content
// — lock screens stay clean ("Người ấy vừa nhắn cho bạn"), aligned with the
// app's no-tracking posture. Skip-self via the memberIds filter, localized
// vi/en per recipient device, plus a durable inbox entry (type chat_message).
exports.notifyChatMessage = onDocumentCreated(
  {document: "couples/{coupleId}/messages/{messageId}", region: "us-central1"},
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Chat-message notification skipped because snapshot is missing.");
      return;
    }

    const message = snapshot.data() || {};

    // Love notes mirrored into chat (auto-migration, 2026-06-14) carry
    // migratedFromNote:true. They already pinged the partner via notifyLoveNote
    // on the source note, so a chat push here would be a duplicate — and a
    // one-time backfill of old notes must never spam. Skip them entirely.
    if (message.migratedFromNote === true) {
      return;
    }

    const coupleId = `${event.params.coupleId || ""}`.trim();
    const authorUserId = `${message.authorUserId || ""}`.trim();
    const text = `${message.text || ""}`.trim();

    // Skip empty messages (the security rule forbids them anyway).
    if (!text) {
      return;
    }

    if (!coupleId || !authorUserId) {
      logger.warn("Chat-message notification skipped because required fields are missing.", {
        coupleId,
        authorUserId,
      });
      return;
    }

    const coupleSnapshot = await db.collection("couples").doc(coupleId).get();
    if (!coupleSnapshot.exists) {
      logger.warn("Chat-message notification skipped because couple document was not found.", {
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
      logger.info("Chat-message notification skipped because there is no partner to notify yet.", {
        coupleId,
      });
      return;
    }

    // Presence suppression (2026-06-19): don't ping a recipient who is right now
    // in the conversation. The chat client writes a dedicated presence stamp
    // (couples/{id}/receipts/{uid}.chatActiveAt = serverTimestamp) on a ~20s
    // heartbeat while the chat is the active screen, and DELETES it the instant
    // they leave (tab switch / background). So a fresh chatActiveAt means
    // "watching live" → skip both the inbox row and the push for them. The
    // window is only a crash backstop (an app killed mid-chat stops heartbeating
    // → presence goes stale within ACTIVE_WINDOW_MS → notifications resume).
    // NB: this is a distinct field from `readAt` on purpose — readAt is the last
    // read time (lingers after leaving) and would over-suppress. Fail-open: any
    // read error leaves the recipient in (better an extra ping than a silent drop).
    const ACTIVE_WINDOW_MS = 45 * 1000;
    const nowMs = Date.now();
    const presence = await Promise.all(
      recipientIds.map(async (rid) => {
        try {
          const receiptSnap = await db
            .collection("couples").doc(coupleId)
            .collection("receipts").doc(rid)
            .get();
          const activeAt = receiptSnap.exists ?
            receiptSnap.get("chatActiveAt") : null;
          const activeMs = activeAt && typeof activeAt.toMillis === "function" ?
            activeAt.toMillis() : 0;
          const active = activeMs > 0 && (nowMs - activeMs) <= ACTIVE_WINDOW_MS;
          return {rid, active};
        } catch (err) {
          return {rid, active: false};
        }
      }),
    );
    const idleRecipientIds = presence.filter((p) => !p.active).map((p) => p.rid);

    if (idleRecipientIds.length === 0) {
      logger.info("Chat-message notification skipped — recipient is active in the chat.", {
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
      logger.warn("Could not load author profile for chat-message notification.", {
        coupleId,
        authorUserId,
        message: err && err.message,
      });
    }
    authorName = normalizeActorName(authorName);

    // Inbox record: structured, content-free (no excerpt — privacy by design).
    // Only for idle recipients — an active reader saw the message live.
    await writeInboxNotifications(idleRecipientIds, {
      type: "chat_message",
      coupleId,
      actorUserId: authorUserId,
      actorName: authorName,
    });

    const result = await sendToRecipientDevices(
      idleRecipientIds,
      (languageCode) => buildChatMessageText(languageCode, authorName),
      {
        type: "chat_message",
        coupleId,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Chat-message notification skipped because recipient has no active FCM tokens.", {
        coupleId,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Chat-message notification had delivery failures.", {
        coupleId,
        failures: result.failures,
      });
    }

    logger.info("Processed chat-message notification.", {
      coupleId,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  },
);

// Partner scheduled-reminder confirmation (feature partner-nudge, 2026-06-29):
// when A creates a timed reminder FOR B (couples/{id}/partnerReminders), push a
// one-off confirmation to B. This serves double duty: it tells B "your person
// set a reminder for you" AND wakes B's app so its watcher arms the LOCAL
// notification (local-on-B scheduling needs the app to have synced the doc).
// PUSH ONLY — no inbox row (the reminder itself will fire locally later, like
// every other local reminder, and those never appear in the notification
// center). Fail-open. NB: the recurring local fire happens on B's device; this
// CF only confirms the *set* action once on create.
exports.notifyPartnerReminderSet = onDocumentCreated(
  {document: "couples/{coupleId}/partnerReminders/{reminderId}", region: "us-central1"},
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const reminder = snapshot.data() || {};
    const coupleId = `${event.params.coupleId || ""}`.trim();
    const authorUserId = `${reminder.authorUserId || ""}`.trim();
    const text = `${reminder.text || ""}`.trim();
    const minuteOfDay = Number.isFinite(reminder.minuteOfDay) ?
      reminder.minuteOfDay : null;

    if (!text || !coupleId || !authorUserId) {
      return;
    }

    const coupleSnapshot = await db.collection("couples").doc(coupleId).get();
    if (!coupleSnapshot.exists) {
      return;
    }

    const memberIds = Array.isArray(coupleSnapshot.get("memberIds")) ?
      coupleSnapshot.get("memberIds") : [];
    // Recipient = the partner the reminder is FOR (everyone but the author).
    const recipientIds = memberIds.filter(
      (memberId) => typeof memberId === "string" && memberId.trim() && memberId !== authorUserId,
    );
    if (recipientIds.length === 0) {
      return;
    }

    let authorName = "";
    try {
      const authorSnap = await db.collection("users").doc(authorUserId).get();
      authorName = `${(authorSnap.exists && authorSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load author profile for partner-reminder-set notification.", {
        coupleId,
        message: err && err.message,
      });
    }
    authorName = normalizeActorName(authorName);

    const result = await sendToRecipientDevices(
      recipientIds,
      (languageCode) =>
        buildPartnerReminderSetText(languageCode, authorName, text, minuteOfDay),
      {
        type: "partner_reminder_set",
        coupleId,
      },
    );

    logger.info("Processed partner-reminder-set notification.", {
      coupleId,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  },
);

// Daily mood notification (feature mood, 2026-06-19): when a member shares /
// changes today's mood, ping the partner so they open the app to see it — the
// daily hook. PUSH ONLY (no inbox row): a mood is ephemeral "today" state, not a
// missed-item to log. Fires on mood OR date change (a new day's first share),
// never on a note-only edit, never on deletion.
exports.notifyPartnerMood = onDocumentWritten(
  {document: "couples/{coupleId}/moods/{uid}", region: "us-central1"},
  async (event) => {
    const after = event.data && event.data.after && event.data.after.exists ?
      event.data.after.data() : null;
    if (!after) {
      return; // deletion
    }
    const before = event.data && event.data.before && event.data.before.exists ?
      event.data.before.data() : null;

    const coupleId = `${event.params.coupleId || ""}`.trim();
    const authorUserId = `${event.params.uid || ""}`.trim();
    const mood = `${after.mood || ""}`.trim();
    const date = `${after.date || ""}`.trim();
    const beforeMood = `${(before && before.mood) || ""}`.trim();
    const beforeDate = `${(before && before.date) || ""}`.trim();

    // Only a real mood change (or a new day's first share) is worth a ping —
    // a note-only edit or metadata re-save is not.
    if (!mood || (mood === beforeMood && date === beforeDate)) {
      return;
    }
    if (!coupleId || !authorUserId) {
      logger.warn("Mood notification skipped because required fields are missing.", {
        coupleId,
        authorUserId,
      });
      return;
    }

    const coupleSnapshot = await db.collection("couples").doc(coupleId).get();
    if (!coupleSnapshot.exists) {
      logger.warn("Mood notification skipped because couple document was not found.", {
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
      logger.info("Mood notification skipped because there is no partner to notify yet.", {
        coupleId,
      });
      return;
    }

    let authorName = "";
    try {
      const authorSnap = await db.collection("users").doc(authorUserId).get();
      authorName = `${(authorSnap.exists && authorSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load author profile for mood notification.", {
        coupleId,
        authorUserId,
        message: err && err.message,
      });
    }
    authorName = normalizeActorName(authorName);

    // Push only — no writeInboxNotifications (mood is ephemeral "today" state).
    const result = await sendToRecipientDevices(
      recipientIds,
      (languageCode) => buildPartnerMoodText(languageCode, authorName, mood),
      {
        type: "partner_mood",
        coupleId,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Mood notification skipped because recipient has no active FCM tokens.", {
        coupleId,
      });
      return;
    }
    if (result.failures.length > 0) {
      logger.warn("Mood notification had delivery failures.", {
        coupleId,
        failures: result.failures,
      });
    }
    logger.info("Processed mood notification.", {
      coupleId,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
    });
  },
);

// ── Love Note → Chat auto-migration (2026-06-14) ───────────────────────────
// The couple chat replaces the old two-way love notes. Users still on an older
// build keep writing love notes, and their (possibly already-updated) partner
// must not lose them — so every love note is mirrored into the chat as a real
// message:
//   • mirrorNoteHistoryToChat (trigger) — each NEW noteHistory entry, in real
//     time, so a version-skewed couple stays in sync.
//   • migrateLoveNotesToChat (callable) — one-time backfill of a couple's
//     EXISTING notes, fired lazily by the updated client when chat opens.
// Mirrored messages carry migratedFromNote:true (notifyChatMessage skips them,
// so no duplicate push vs notifyLoveNote, and a backfill never spams). The
// message id is derived from the note entry id (lovenote_<entryId>), so the
// whole thing is idempotent — re-running only overwrites the same doc.
async function mirrorNoteToChat(coupleId, entryId, data) {
  const cid = `${coupleId || ""}`.trim();
  const eid = `${entryId || ""}`.trim();
  const authorUserId = `${(data && data.authorUserId) || ""}`.trim();
  const text = `${(data && data.text) || ""}`.trim();
  if (!cid || !eid || !authorUserId || !text) {
    return false;
  }
  // Preserve the note's original time so it sorts into the conversation where
  // it was actually written; fall back to now only if it's somehow missing.
  const createdAt = (data && data.createdAt) ||
    admin.firestore.FieldValue.serverTimestamp();
  await db
    .collection("couples").doc(cid)
    .collection("messages").doc(`lovenote_${eid}`)
    .set({authorUserId, text, createdAt, migratedFromNote: true});
  return true;
}

exports.mirrorNoteHistoryToChat = onDocumentCreated(
  {document: "couples/{coupleId}/noteHistory/{entryId}", region: "us-central1"},
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }
    await mirrorNoteToChat(
      event.params.coupleId,
      event.params.entryId,
      snapshot.data() || {},
    );
  },
);

exports.migrateLoveNotesToChat = onCall(
  {region: "us-central1"},
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const coupleId = `${(request.data && request.data.coupleId) || ""}`.trim();
    if (!coupleId) {
      throw new HttpsError("invalid-argument", "coupleId is required.");
    }

    const coupleRef = db.collection("couples").doc(coupleId);
    const coupleSnap = await coupleRef.get();
    if (!coupleSnap.exists) {
      throw new HttpsError("not-found", "Couple not found.");
    }
    const memberIds = Array.isArray(coupleSnap.get("memberIds")) ?
      coupleSnap.get("memberIds") : [];
    if (!memberIds.includes(uid)) {
      throw new HttpsError("permission-denied", "Not a member of this couple.");
    }

    // Already backfilled → nothing to do; the trigger keeps new notes in sync.
    if (coupleSnap.get("loveNotesMigratedToChat") === true) {
      return {alreadyDone: true, migrated: 0};
    }

    const historySnap = await coupleRef.collection("noteHistory").get();
    const results = await Promise.all(
      historySnap.docs.map(
        (doc) => mirrorNoteToChat(coupleId, doc.id, doc.data() || {}),
      ),
    );
    const migrated = results.filter(Boolean).length;

    await coupleRef.set({loveNotesMigratedToChat: true}, {merge: true});
    logger.info("Backfilled love notes into chat.", {coupleId, migrated});
    return {alreadyDone: false, migrated};
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

    // Answering member's display name. Kept RAW (possibly "") on purpose:
    // • the inbox doc drops empty fields, so the client renders its OWN localized
    //   fallback instead of a hardcoded Vietnamese one on an English device;
    // • the push localizes the fallback per recipient device in buildDailyAnswerText.
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

    // Who has answered today? The responses collection holds at most one doc per
    // member (id === uid), so reading it once answers three questions:
    //  1. copy — has the RECIPIENT already answered? If yes the push must NOT tell
    //     them to "answer yours to unlock" (they did). Checking the recipient's own
    //     doc instead of a total count removes the race the count had: when both
    //     partners submit within the same second, the count this function reads can
    //     still be 1 and the just-answered partner got nudged to answer again.
    //  2. the `bothAnswered` data flag the client uses to drop today's now-stale
    //     local nudges (see §6 of CLAUDE.md).
    //  3. the streak/journal marker below.
    // Fail-open to the nudge on any read error (an extra nudge beats wrong copy).
    const date = `${event.params.date || ""}`.trim();
    let answeredUids = new Set();
    try {
      if (date) {
        const responsesSnap = await db
          .collection("couples").doc(coupleId)
          .collection("dailyAnswers").doc(date)
          .collection("responses")
          .get();
        answeredUids = new Set(responsesSnap.docs.map((doc) => doc.id));
      }
    } catch (err) {
      logger.warn("Could not read daily responses; defaulting to answer nudge.", {
        coupleId,
        message: err && err.message,
      });
    }
    // True when every recipient has answered too — i.e. the pair is complete.
    // (A couple has exactly two members, so this is a single-recipient check.)
    const bothAnswered = answeredUids.size > 0 &&
      recipientIds.every((recipientId) => answeredUids.has(recipientId));

    // Stamp the streak/journal marker server-side once BOTH have answered.
    // Previously only the client did this (in submitAnswer, best-effort inside a
    // swallowed try/catch), which lost the day in two real cases:
    //  • both submit at the same moment → each client reads only its own doc → the
    //    flag is never written, so the card reveals but the streak + journal skip
    //    that day entirely;
    //  • the marker doc doesn't exist yet → the member-write rule demands
    //    date/questionVi/questionEn on every write, so a merge carrying only
    //    `bothAnswered` is DENIED.
    // The Admin SDK bypasses rules, so this write always lands. Best-effort: a
    // failure must never break the notification.
    if (bothAnswered && date) {
      try {
        await db
          .collection("couples").doc(coupleId)
          .collection("dailyAnswers").doc(date)
          .set({
            // `date` is REQUIRED on the marker: the streak + journal queries
            // orderBy('date') and Firestore drops docs missing the field. When
            // both clients failed to publish (offline), this stamp CREATES the
            // marker, so without `date` the day would vanish from both.
            date,
            bothAnswered: true,
            revealedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
      } catch (err) {
        logger.warn("Could not stamp bothAnswered marker.", {
          coupleId,
          date,
          message: err && err.message,
        });
      }
    }

    // Backfilled answers (the account-gated catch-up gate writes `backfill:true`
    // on responses for PAST days, 2026-09-05 — the admin restore script does
    // too): the marker stamp above still runs so the streak/journal recover,
    // but there is nothing to announce — the copy says "hôm nay", the inbox
    // item would be a dead-end, and the wake would cancel the partner's TODAY
    // nudges for a day that isn't today.
    const responseData = (event.data && typeof event.data.data === "function") ?
      (event.data.data() || {}) : {};
    if (responseData.backfill === true) {
      logger.info("Daily-answer notification skipped for backfilled response.", {
        coupleId,
        date,
        authorUserId,
        bothAnswered,
      });
      return;
    }

    await writeInboxNotifications(recipientIds, {
      type: "daily_question",
      coupleId,
      actorUserId: authorUserId,
      // Empty → dropped by sanitizeInboxPayload → client uses its own localized
      // "Người ấy"/"Your partner" fallback.
      actorName: authorName,
      date,
      // Lets the notification center title match the push ("cả hai đã trả lời"
      // instead of only "<name> answered"). Stored as a real boolean (inbox docs
      // are structured data, unlike the string-only FCM data payload).
      bothAnswered,
    });

    const result = await sendToRecipientDevices(
      recipientIds,
      (languageCode) => buildDailyAnswerText(languageCode, authorName, bothAnswered),
      {
        type: "daily_question",
        coupleId,
        // Lets the recipient's app cancel today's local daily-question nudges the
        // moment the pair is complete (2026-08-09). Without this the FIRST
        // answerer — who normally leaves the app right after answering — keeps the
        // nudges armed from when only they had answered, so hours later they fire
        // with copy that has become false ("người ấy chưa trả lời", "sắp lỡ mất
        // chuỗi"). FCM data values must be strings.
        bothAnswered: bothAnswered ? "true" : "false",
      },
      // Only the pair-completing push needs to wake the recipient's app (iOS
      // content-available + Android data-only companion); the "answer yours to
      // unlock" one has nothing for the client to act on.
      {wakeClients: bothAnswered},
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

    await writeInboxNotifications([authorUserId], {
      type: "photo_reaction",
      coupleId,
      actorUserId: reactorUid,
      actorName: reactorName,
      photoId,
      emoji,
    });

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

// Reaction on a daily-question answer (feature: daily-question reactions).
// Fires when a member reacts to their PARTNER's answer and notifies the answer's
// author. Path-scoped to `answerReactions`, so it never overlaps
// notifyPhotoReaction (which triggers on the photos `reactions` subcollection).
//
// The answer's author and the day come from the trigger path, not from document
// fields, so a forged/stale field can never redirect the push.
exports.notifyDailyAnswerReaction = onDocumentCreated(
  {
    document:
      "couples/{coupleId}/dailyAnswers/{date}/responses/{answerAuthorUid}/answerReactions/{reactorUid}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Answer reaction notification skipped because snapshot is missing.");
      return;
    }

    const reaction = snapshot.data() || {};
    const coupleId = `${event.params.coupleId || ""}`.trim();
    const date = `${event.params.date || ""}`.trim();
    const answerAuthorUid = `${event.params.answerAuthorUid || ""}`.trim();
    // The answerReactions doc id === the reacting member's uid by convention.
    const reactorUid = `${event.params.reactorUid || ""}`.trim();
    const emoji = `${reaction.emoji || "❤️"}`.trim() || "❤️";

    if (!coupleId || !date || !answerAuthorUid || !reactorUid) {
      logger.warn("Answer reaction notification skipped because required fields are missing.", {
        coupleId,
        date,
        answerAuthorUid,
        reactorUid,
      });
      return;
    }

    // Defence in depth — the rules already forbid reacting to your own answer.
    if (reactorUid === answerAuthorUid) {
      return;
    }

    // Reacting member's display name. Left RAW here (empty when unknown) so the
    // fallback can be localized per recipient device below — hardcoding
    // "Người ấy" is what produced the mixed-language push fixed in 1.4.2.
    let reactorName = "";
    try {
      const reactorSnap = await db.collection("users").doc(reactorUid).get();
      reactorName = `${(reactorSnap.exists && reactorSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load reactor profile for answer reaction notification.", {
        coupleId,
        reactorUid,
        message: err && err.message,
      });
    }

    // Inbox drops an empty name so the client localizes its own fallback.
    const inboxPayload = {
      type: "daily_answer_reaction",
      coupleId,
      date,
      emoji,
      actorUserId: reactorUid,
    };
    if (reactorName) {
      inboxPayload.actorName = reactorName;
    }
    await writeInboxNotifications([answerAuthorUid], inboxPayload);

    const result = await sendToRecipientDevices(
      [answerAuthorUid],
      (languageCode) => buildAnswerReactionText(languageCode, reactorName, emoji),
      {
        type: "daily_answer_reaction",
        coupleId,
        date,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Answer reaction notification skipped because the author has no active FCM tokens.", {
        coupleId,
        date,
      });
      return;
    }

    if (result.failures.length > 0) {
      logger.warn("Answer reaction notification had delivery failures.", {
        coupleId,
        date,
        failures: result.failures,
      });
    }

    logger.info("Processed answer reaction notification.", {
      coupleId,
      date,
      attemptedTokens: result.deviceCount,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  },
);

// ── Care message (feature care-message) ────────────────────────────────────
// One member sends a short "quan tâm" note; the partner gets it as a push whose
// title/body ARE the note, plus a durable inbox item.
//
// Deliberately NOT content-free and NOT localized: every other push here hides
// its content behind a localized template, but this feature's whole point is
// that the words the sender wrote land on the partner's lock screen verbatim.
// The rules bound the text (title ≤ 60, body ≤ 200, non-empty) and we clamp
// again here, so nothing unbounded reaches FCM.
// No wakeClients — there is nothing for the client to do in the background.
exports.notifyCareMessage = onDocumentCreated(
  {document: "couples/{coupleId}/careMessages/{messageId}", region: "us-central1"},
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Care message notification skipped because snapshot is missing.");
      return;
    }

    const care = snapshot.data() || {};
    const coupleId = `${event.params.coupleId || ""}`.trim();
    const messageId = `${event.params.messageId || ""}`.trim();
    const authorUserId = `${care.authorUserId || ""}`.trim();
    const title = `${care.title || ""}`.trim().slice(0, 60);
    const body = `${care.body || ""}`.trim().slice(0, 200);

    // Seeded/backfilled notes (admin scripts write `backfill: true`) are
    // history, not news: keep them out of the inbox and off the lock screen.
    if (care.backfill === true) {
      logger.info("Care message notification skipped for backfilled note.", {coupleId, messageId});
      return;
    }

    if (!coupleId || !authorUserId || !title || !body) {
      logger.warn("Care message notification skipped because required fields are missing.", {
        coupleId,
        messageId,
        authorUserId,
        hasTitle: !!title,
        hasBody: !!body,
      });
      return;
    }

    const coupleSnapshot = await db.collection("couples").doc(coupleId).get();
    if (!coupleSnapshot.exists) {
      logger.warn("Care message notification skipped because couple document was not found.", {
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
      logger.info("Care message notification skipped because there is no partner to notify yet.", {
        coupleId,
      });
      return;
    }

    let authorName = "";
    try {
      const authorSnap = await db.collection("users").doc(authorUserId).get();
      authorName = `${(authorSnap.exists && authorSnap.get("displayName")) || ""}`.trim();
    } catch (err) {
      logger.warn("Could not load author profile for care message notification.", {
        coupleId,
        authorUserId,
        message: err && err.message,
      });
    }
    authorName = normalizeActorName(authorName);

    await writeInboxNotifications(recipientIds, {
      type: "care_message",
      coupleId,
      actorUserId: authorUserId,
      actorName: authorName,
      careMessageId: messageId,
      title,
      body,
    });

    // Same text on every device, whatever its language — see the note above.
    const result = await sendToRecipientDevices(
      recipientIds,
      () => ({title, body}),
      {
        type: "care_message",
        coupleId,
        careMessageId: messageId,
      },
    );

    if (result.deviceCount === 0) {
      logger.info("Care message notification skipped because recipient has no active FCM tokens.", {
        coupleId,
        messageId,
      });
      return;
    }
    if (result.failures.length > 0) {
      logger.warn("Care message notification had delivery failures.", {
        coupleId,
        messageId,
        failures: result.failures,
      });
    }
    logger.info("Processed care message notification.", {
      coupleId,
      messageId,
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
// `options.wakeClients` (2026-08-09) additionally wakes the recipient app so it
// can ACT on the payload with no UI running — for callers whose data the client
// must process (e.g. dropping stale local nudges). Platform mechanics differ:
//  • iOS: `aps.content-available` on the alert push itself (mixed payload — the
//    banner still shows, and the background isolate runs). No extra send.
//  • Android: a notification-payload push received in background/terminated goes
//    straight to the system tray — onMessageReceived (⇒ Flutter's
//    onBackgroundMessage) is NEVER called for it; only DATA-ONLY messages reach
//    the handler there. So each Android device additionally gets a data-only
//    companion (high priority, same `dataExtra`, deliberately WITHOUT title/body
//    so the foreground handler shows no second banner).
// Per-type mute prefs (D-notif-4): maps a push `type` to the device-doc field
// the user can switch off. Types not listed (love_note, partner_joined/left)
// are always-on and never filtered. Absent field on a device → not muted.
const PUSH_TYPE_PREF_FIELD = {
  photo_posted: "pushPhoto",
  photo_reaction: "pushReaction",
  daily_question: "pushDailyQuestion",
};

async function sendToRecipientDevices(recipientIds, buildText, dataExtra, options = {}) {
  const muteField = PUSH_TYPE_PREF_FIELD[dataExtra && dataExtra.type];
  const deviceDocs = [];
  // Real iOS app-icon badge (D-notif-2): per recipient, how many unread inbox
  // notifications they have right now. The inbox doc for THIS event was already
  // written by the sender before this runs, so it's included → the badge equals
  // the true unread total. Replaces the old hardcoded `badge: 1`.
  const unreadByRecipient = {};
  for (const recipientId of recipientIds) {
    try {
      const countSnap = await db
        .collection("users").doc(recipientId)
        .collection("notifications")
        .where("read", "==", false)
        .count().get();
      unreadByRecipient[recipientId] = countSnap.data().count || 1;
    } catch (err) {
      unreadByRecipient[recipientId] = 1;
    }

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

      // Skip this device when the user muted this push type on it. Only the
      // PUSH is suppressed — the durable inbox record is still written, so the
      // notification center stays a complete history.
      if (muteField && doc.get(muteField) === false) {
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

  // Each outgoing entry keeps its device so delivery failures can be attributed
  // (and dead tokens pruned) even after companion messages are appended — a bare
  // `messages[index] → deviceDocs[index]` mapping would break then.
  const outgoing = deviceDocs.map((device) => {
    const {title, body} = buildText(device.languageCode);
    return {
      device,
      message: {
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
              badge: unreadByRecipient[device.recipientId] || 1,
              // Wake the app's background isolate on iOS so it can ACT on this
              // push, not just display it. Opt-in per caller — a background wake
              // spends one of iOS's rationed budget slots, so we don't burn one
              // on every push. Mixed payload (alert + content-available) still
              // shows the banner normally.
              ...(options.wakeClients ? {contentAvailable: true} : {}),
            },
          },
        },
      },
    };
  });

  // Android wake companion — see the wakeClients note above the function. The
  // data payload carries NO title/body on purpose: in the foreground the client's
  // onMessage handler acts on the data, then bails before showing a banner.
  if (options.wakeClients) {
    for (const device of deviceDocs) {
      if (device.platform !== "android") {
        continue;
      }
      outgoing.push({
        device,
        message: {
          token: device.token,
          data: {...dataExtra},
          android: {priority: "high"},
        },
      });
    }
  }

  const response = await admin.messaging().sendEach(outgoing.map((o) => o.message));

  const invalidRefs = [];
  const failures = [];
  response.responses.forEach((res, index) => {
    if (res.success) {
      return;
    }

    const {device} = outgoing[index];
    const code = res.error && res.error.code;
    failures.push({
      recipientId: device.recipientId,
      platform: device.platform,
      code: code || "unknown",
      message: res.error && res.error.message,
    });

    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      // A device may appear twice (alert + companion) — the duplicate delete is a
      // no-op.
      invalidRefs.push(device.ref);
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

// Inbox (notification center): every push ALSO writes a durable record to each
// recipient's users/{uid}/notifications subcollection. The push itself is
// ephemeral — this doc is the source of truth the in-app notification center
// reads, so the list survives app-kill / reinstall / a missed push, completely
// independent of FCM delivery (or whether notifications are even enabled).
//
// Stored as STRUCTURED data (type + actorName + ids), NOT a pre-rendered
// sentence, so the client renders the text in the user's CURRENT app language —
// the inbox is never frozen in the send-time locale.
//
// Resilient by design: any failure here is logged and swallowed so it can never
// break the push send. Admin SDK writes bypass security rules (clients are
// create:forbidden on this subcollection — they may only read / mark-read /
// delete their own).
async function writeInboxNotifications(recipientIds, payload) {
  const ids = (recipientIds || []).filter(
    (id) => typeof id === "string" && id.trim(),
  );
  if (ids.length === 0) {
    return;
  }

  const doc = {
    ...sanitizeInboxPayload(payload),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  };

  await Promise.all(
    ids.map((uid) =>
      db
        .collection("users").doc(uid)
        .collection("notifications")
        .add(doc)
        .catch((err) => {
          logger.warn("Failed to write inbox notification.", {
            uid,
            type: payload && payload.type,
            message: err && err.message,
          });
          return null;
        }),
    ),
  );
}

// Drop undefined/null and empty-string fields (Firestore rejects undefined; we
// never want to persist empty optional ids/excerpts that the client would have
// to special-case).
function sanitizeInboxPayload(payload) {
  const out = {};
  for (const [key, value] of Object.entries(payload || {})) {
    if (value === undefined || value === null) {
      continue;
    }
    if (typeof value === "string" && !value.trim()) {
      continue;
    }
    out[key] = value;
  }
  return out;
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

    // 2b) Notification inbox (notification center) for this user — a per-user
    //     subcollection, so it does NOT cascade when the user doc is deleted.
    //     Erase it explicitly to satisfy account-deletion completeness
    //     (App Store 5.1.1(v) / Google Play) and avoid orphaned records.
    await db.recursiveDelete(userRef.collection("notifications")).catch((err) => {
      logger.warn("Failed to delete notification inbox during account deletion.", {
        uid,
        message: err && err.message,
      });
      return null;
    });

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

// Couple teardown when a member LEAVES (not account deletion). The client used
// to do this teardown itself, but it could only delete the photos subcollection
// + couple_codes — notes, noteHistory, dailyAnswers and per-photo reactions were
// left orphaned in Firestore (subcollections don't cascade when the parent doc
// is deleted, and the client SDK has no recursiveDelete). Routing the
// sole-member case through this callable lets the admin SDK recursively delete
// EVERYTHING with no orphans. Mirrors the account-deletion teardown.
exports.leaveCoupleCleanup = onCall(
  {region: "us-central1"},
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Bạn cần đăng nhập để rời khỏi không gian này.",
      );
    }

    const coupleId = `${(request.data && request.data.coupleId) || ""}`.trim();
    if (!coupleId) {
      throw new HttpsError("invalid-argument", "Thiếu coupleId.");
    }

    const coupleRef = db.collection("couples").doc(coupleId);
    const snap = await coupleRef.get();
    if (!snap.exists) {
      // Already gone — nothing to tear down. Idempotent success.
      return {success: true, alreadyGone: true};
    }

    const data = snap.data() || {};
    const memberIds = Array.isArray(data.memberIds) ? data.memberIds : [];

    // SECURITY: only an actual member may tear down / demote this couple, so a
    // caller can't pass someone else's coupleId to destroy or demote it.
    if (!memberIds.includes(uid)) {
      throw new HttpsError(
        "permission-denied",
        "Bạn không phải thành viên của không gian này.",
      );
    }

    // Same semantics as account deletion: removing uid; if that empties the
    // couple, recursiveDelete everything; otherwise demote to waiting_partner.
    await handleCoupleOnAccountDeletion(coupleId, uid);
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

    // Point the link at our on-brand action page instead of Firebase's default.
    verifyUrl = rewriteActionLink(verifyUrl, lang);

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

  // Love-note history (feature love-note-history): append-only archive. Without
  // this the entries linger as orphans after the couple doc is gone.
  tasks.push(
    db.recursiveDelete(coupleRef.collection("noteHistory")).catch((err) => {
      logger.warn("Failed to recursively delete noteHistory during couple teardown.", {
        coupleId: coupleRef.id,
        message: err && err.message,
      });
      return null;
    }),
  );

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

  // Couple entry code (feature couple-code): the couple_codes/{code} pointer is
  // a TOP-LEVEL doc, not a subcollection, so recursiveDelete on the couple won't
  // touch it. Remove it explicitly or the 6-char code stays mapped to a dead
  // couple (and can't be reused).
  const coupleCode = `${(coupleData && coupleData.coupleCode) || ""}`.trim().toUpperCase();
  if (coupleCode) {
    tasks.push(
      db.collection("couple_codes").doc(coupleCode).delete().catch(() => null),
    );
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

// Localized copy for the partner-left push, keyed by the recipient device's
// languageCode. Unknown/missing codes fall back to Vietnamese.
const PARTNER_LEFT_COPY = {
  vi: {
    title: (name) => `${name} đã rời khỏi không gian chung`,
    body: "Khi nào sẵn sàng, hai bạn có thể kết nối lại nhé 💛",
  },
  en: {
    title: (name) => `${name} has left your shared space`,
    body: "You can reconnect whenever you're both ready 💛",
  },
};

function buildPartnerLeftText(languageCode, leaverName) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = PARTNER_LEFT_COPY[code] || PARTNER_LEFT_COPY.vi;
  return {
    title: copy.title(leaverName),
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

// Localized copy for the chat-message push (feature chat, D4), keyed by the
// recipient device's languageCode. Unknown/missing codes fall back to
// Vietnamese. DELIBERATELY content-free (design §C): the lock screen never
// previews the message text — only that the partner wrote.
const CHAT_MESSAGE_COPY = {
  vi: {
    title: "Tin nhắn mới 💬",
    body: (author) => `${author} vừa gửi cho bạn một tin nhắn 💌`,
  },
  en: {
    title: "New message 💬",
    body: (name) => `${name} just sent you a message 💌`,
  },
};

// Mood push copy (feature mood) — content-free teaser (no mood/note leaked),
// just a warm nudge to open and see how your person feels today.
const PARTNER_MOOD_COPY = {
  vi: {
    title: "Tâm trạng hôm nay 💗",
    // Show the mood when we recognise it ("Anh Tuấn đang thấy Nhớ"); otherwise a
    // gentle generic nudge.
    body: (name, moodLabel) => moodLabel ?
      `${name} đang thấy ${moodLabel}` :
      `${name} vừa chia sẻ tâm trạng hôm nay — ghé xem nhé`,
  },
  en: {
    title: "Today's mood 💗",
    body: (name, moodLabel) => moodLabel ?
      `${name} is feeling ${moodLabel}` :
      `${name} just shared how they feel today — take a peek`,
  },
};

// Localized mood labels (mirror the app's app_*.arb mood keys) so the push can
// name the mood. Unknown keys fall back to the generic copy above.
const MOOD_LABELS = {
  vi: {
    happy: "Vui", loved: "Hạnh phúc", missing: "Nhớ", calm: "Bình yên",
    meh: "Bình thường", tired: "Mệt", sad: "Buồn", stressed: "Căng thẳng",
  },
  en: {
    happy: "Happy", loved: "Loved", missing: "Missing you", calm: "Calm",
    meh: "Meh", tired: "Tired", sad: "Sad", stressed: "Stressed",
  },
};

function buildPartnerMoodText(languageCode, authorName, moodKey) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = PARTNER_MOOD_COPY[code] || PARTNER_MOOD_COPY.vi;
  const labels = MOOD_LABELS[code] || MOOD_LABELS.vi;
  const moodLabel = labels[`${moodKey || ""}`.trim()] || "";
  return {
    title: copy.title,
    body: copy.body(authorName, moodLabel),
  };
}

function buildChatMessageText(languageCode, authorName) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = CHAT_MESSAGE_COPY[code] || CHAT_MESSAGE_COPY.vi;
  return {
    title: copy.title,
    body: copy.body(authorName),
  };
}

// Partner scheduled-reminder confirmation copy (feature partner-nudge). Tells
// B that A set a timed reminder for them, with the time when known.
const PARTNER_REMINDER_SET_COPY = {
  vi: {
    title: "Lời nhắc từ người ấy ⏰",
    body: (name, text, hhmm) => hhmm ?
      `${name} đặt nhắc bạn: ${text} lúc ${hhmm}` :
      `${name} đặt nhắc bạn: ${text}`,
  },
  en: {
    title: "A reminder from your partner ⏰",
    body: (name, text, hhmm) => hhmm ?
      `${name} set a reminder for you: ${text} at ${hhmm}` :
      `${name} set a reminder for you: ${text}`,
  },
};

function buildPartnerReminderSetText(languageCode, authorName, text, minuteOfDay) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = PARTNER_REMINDER_SET_COPY[code] || PARTNER_REMINDER_SET_COPY.vi;
  return {
    title: copy.title,
    body: copy.body(authorName, truncateText(`${text || ""}`.trim(), 120),
      formatMinuteOfDay(minuteOfDay)),
  };
}

// Format wall-clock minutes-since-midnight (0..1439) as "HH:MM". Returns "" for
// null/out-of-range so callers can drop the time gracefully.
function formatMinuteOfDay(minuteOfDay) {
  if (!Number.isFinite(minuteOfDay) || minuteOfDay < 0 || minuteOfDay > 1439) {
    return "";
  }
  const h = Math.floor(minuteOfDay / 60);
  const m = minuteOfDay % 60;
  return `${`${h}`.padStart(2, "0")}:${`${m}`.padStart(2, "0")}`;
}

// Localized copy for the daily-question push (feature #5), keyed by the
// recipient device's languageCode. Unknown/missing codes fall back to
// Vietnamese. `body` nudges a recipient who HASN'T answered yet to answer and
// unlock the reveal; `bodyBoth` is used when the recipient has ALREADY answered
// (this answer completed the pair) so we never tell them to answer again.
const DAILY_QUESTION_COPY = {
  vi: {
    // Localized fallback when the partner hasn't set a display name — the shared
    // normalizeActorName() would hardcode Vietnamese on an English device.
    partnerFallback: "Người ấy",
    title: (author) => `${author} đã trả lời câu hỏi hôm nay 💞`,
    body: "Trả lời câu hỏi của bạn để mở khoá câu trả lời của người ấy nhé.",
    bodyBoth: "Cả hai đã trả lời rồi — mở app xem câu trả lời của nhau nhé!",
  },
  en: {
    partnerFallback: "Your partner",
    title: (name) => `${name} answered today's question 💞`,
    body: "Answer yours to unlock your partner's reply.",
    bodyBoth: "You've both answered — open the app to read each other's replies!",
  },
};

// `authorName` may be empty — the fallback is picked per RECIPIENT language here
// rather than baked in Vietnamese by the caller.
function buildDailyAnswerText(languageCode, authorName, bothAnswered) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = DAILY_QUESTION_COPY[code] || DAILY_QUESTION_COPY.vi;
  const name = `${authorName || ""}`.trim() || copy.partnerFallback;
  return {
    title: copy.title(name),
    body: bothAnswered ? copy.bodyBoth : copy.body,
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

// Copy for the daily-answer reaction push (feature: daily-question reactions).
// Carries a per-language `partnerFallback` instead of a hardcoded Vietnamese
// name — the 1.4.2 lesson that produced "Người ấy reacted to your answer" on
// English devices. Content-free: never quotes the answer text.
const ANSWER_REACTION_COPY = {
  vi: {
    title: "Dear Embeiu",
    partnerFallback: "Người ấy",
    body: (name, emoji) => `${name} đã thả ${emoji} cho câu trả lời của bạn`,
  },
  en: {
    title: "Dear Embeiu",
    partnerFallback: "Your partner",
    body: (name, emoji) => `${name} reacted ${emoji} to your answer`,
  },
};

function buildAnswerReactionText(languageCode, reactorName, emoji) {
  const code = `${languageCode || ""}`.trim().toLowerCase();
  const copy = ANSWER_REACTION_COPY[code] || ANSWER_REACTION_COPY.vi;
  const name = `${reactorName || ""}`.trim() || copy.partnerFallback;
  return {
    title: copy.title,
    body: copy.body(name, `${emoji || "❤️"}`.trim() || "❤️"),
  };
}

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

// Custom branded password reset email via Resend (feature auth).
// Replaces Firebase's default sendPasswordResetEmail (which sends from
// noreply@tonyembeiu.firebaseapp.com → goes to spam). This callable generates
// the official Firebase reset link via Admin SDK, then delivers it through
// Resend from noreply@dearembeiu.com — a trusted, on-brand sender.
//
// Anti-enumeration: unknown email → return {sent: true} (same as known email)
// so callers can't probe whether an address is registered.
exports.sendCustomPasswordResetEmail = onCall(
  {region: "us-central1", secrets: [RESEND_API_KEY]},
  async (request) => {
    const email = `${(request.data && request.data.email) || ""}`.trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "Email không hợp lệ.");
    }

    const lang = `${(request.data && request.data.languageCode) || ""}`
      .trim()
      .toLowerCase() || "vi";

    // Fetch user record to get displayName for the greeting.
    // If user not found, silently return success (anti-enumeration).
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (err) {
      if (err && err.code === "auth/user-not-found") {
        logger.info("Password reset: email not found (anti-enum).", {email});
        return {sent: true};
      }
      logger.error("Password reset: getUserByEmail failed.", {
        email,
        message: err && err.message,
      });
      throw new HttpsError("internal", "Không thể xử lý yêu cầu.");
    }

    // Generate the official Firebase password reset link.
    let resetUrl;
    try {
      resetUrl = await admin.auth().generatePasswordResetLink(email);
    } catch (err) {
      logger.error("Password reset: link generation failed.", {
        email,
        message: err && err.message,
      });
      throw new HttpsError("internal", "Không thể tạo liên kết đặt lại mật khẩu.");
    }

    const name = `${userRecord.displayName || ""}`.trim();

    // Point the link at our on-brand action page instead of Firebase's default.
    resetUrl = rewriteActionLink(resetUrl, lang);

    const {subject, html} = buildPasswordResetEmail({name, resetUrl, lang});

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
      logger.error("Password reset: Resend request threw.", {
        email,
        message: err && err.message,
      });
      throw new HttpsError("internal", "Không gửi được email đặt lại mật khẩu.");
    }

    if (!response.ok) {
      const detail = await response.text().catch(() => "");
      logger.error("Password reset: Resend returned an error.", {
        email,
        status: response.status,
        detail: detail.slice(0, 500),
      });
      throw new HttpsError("internal", "Không gửi được email đặt lại mật khẩu.");
    }

    logger.info("Password reset email sent.", {email, lang});
    return {sent: true};
  },
);


// ---------------------------------------------------------------------------
// AI daily question (feature endless-questions, 2026-09-05)
// ---------------------------------------------------------------------------
//
// Callable that writes ONE personalised question into today's marker doc
// (couples/{coupleId}/dailyAnswers/{date}) so both phones read the exact same
// text. The client calls it when it is about to render today's card and the
// marker has no question yet; on ANY failure it returns {ok:false, reason} —
// never throws for runtime problems — so the client silently falls back to the
// local bank/template engine and the card is never empty.
//
// Privacy: the prompt carries the couple's recent answers, so it only runs when
// the couple opted in (prefs/home.aiQuestionsEnabled == true) and the two
// people are anonymised to "A" (caller) / "B" (partner) — no names, emails or
// uids ever leave the function.
const Anthropic = require("@anthropic-ai/sdk");

// Anthropic API key. Set before deploy (per project):
//   printf '<KEY>' | firebase functions:secrets:set ANTHROPIC_API_KEY \
//     --project <dev|prod> --data-file -
// A literal "unset" placeholder is treated as "no key" (DEV deploys without a
// real key still work — the callable just answers {ok:false, no_api_key}).
const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

// Swap to "claude-haiku-4-5" if the bill ever matters — roughly 5× cheaper for
// this prompt size, at some cost in how well it picks up on past answers.
const AI_QUESTION_MODEL = "claude-opus-5";
// Hard cap on model calls per couple per day (idempotency alone only keys on
// `date`; without this a member could burn budget by asking for many dates).
const AI_MAX_ATTEMPTS_PER_DAY = 3;

const AI_QUESTION_SYSTEM_PROMPT = [
  "Bạn là người viết câu hỏi mỗi ngày cho một cặp đôi đang dùng app Dear Embeiu.",
  "Nhiệm vụ: viết ĐÚNG 1 câu hỏi cho hôm nay, có cả bản tiếng Việt và bản tiếng Anh.",
  "",
  "Yêu cầu:",
  "- Mỗi bản tối đa 200 ký tự, chỉ một câu hỏi duy nhất.",
  "- Giọng ấm áp, nhẹ nhàng, tôn trọng; hỏi để hai người kể cho nhau nghe.",
  "- Tiếng Việt xưng hô \"chúng mình\" / \"người ấy\" / \"bạn\". KHÔNG dùng tên riêng, KHÔNG dùng \"hai đứa\".",
  "- Dựa vào chủ đề và câu trả lời gần đây để hỏi sâu hơn hoặc nối tiếp (ví dụ nhắc lại một dự định họ từng nói).",
  "- Phù hợp với thứ trong tuần, cột mốc hoặc tâm trạng hôm nay nếu có dữ liệu.",
  "- KHÔNG lặp lại chủ đề của 14 ngày gần nhất.",
  "- Tránh chủ đề sức khoẻ, tài chính, tình dục, xung đột nặng.",
  "- Tối đa 1 emoji (không có cũng được).",
  "- KHÔNG dùng dấu ngoặc nhọn { } hay < >.",
  "- tags: 1–3 từ khoá chủ đề (tiếng Việt, viết thường).",
].join("\n");

const AI_QUESTION_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["vi", "en", "tags"],
  properties: {
    vi: {type: "string"},
    en: {type: "string"},
    tags: {type: "array", items: {type: "string"}},
  },
};

const AI_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

const AI_WEEKDAY_VI = [
  "Chủ nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy",
];

// 'YYYY-MM-DD' -> UTC ms (dates in this feature are wall-clock day keys, never
// instants, so UTC arithmetic keeps the day math exact).
function aiDateToUtcMs(date) {
  const [y, m, d] = date.split("-").map((part) => parseInt(part, 10));
  return Date.UTC(y, m - 1, d);
}

function aiShiftDate(date, deltaDays) {
  const shifted = new Date(aiDateToUtcMs(date) + deltaDays * 86400000);
  return shifted.toISOString().slice(0, 10);
}

function aiTrim(value, max) {
  const text = `${value == null ? "" : value}`.replace(/\s+/g, " ").trim();
  return text.length > max ? `${text.slice(0, max)}…` : text;
}

// Anniversary is stored as a Timestamp by the app, but tolerate a date string
// from older writes.
function aiAnniversaryDateKey(raw) {
  try {
    if (!raw) return null;
    if (typeof raw.toDate === "function") {
      return raw.toDate().toISOString().slice(0, 10);
    }
    if (typeof raw === "string" && AI_DATE_PATTERN.test(raw.slice(0, 10))) {
      return raw.slice(0, 10);
    }
  } catch (_) {
    return null;
  }
  return null;
}

exports.generateDailyQuestion = onCall(
  {
    region: "us-central1",
    secrets: [ANTHROPIC_API_KEY],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const data = request.data || {};
    const coupleId = `${data.coupleId || ""}`.trim();
    const date = `${data.date || ""}`.trim();
    const lang = `${data.lang || "vi"}`.trim() === "en" ? "en" : "vi";
    if (!coupleId) {
      throw new HttpsError("invalid-argument", "coupleId is required.");
    }
    if (!AI_DATE_PATTERN.test(date)) {
      throw new HttpsError("invalid-argument", "date must be YYYY-MM-DD.");
    }
    // Only "today" (±1 day to absorb every client timezone against UTC) may be
    // generated — never arbitrary past/future dates.
    const allowedDates = new Set([-1, 0, 1].map((delta) => {
      const d = new Date();
      d.setUTCDate(d.getUTCDate() + delta);
      return d.toISOString().slice(0, 10);
    }));
    if (!allowedDates.has(date)) {
      return {ok: false, reason: "invalid"};
    }

    const coupleRef = db.collection("couples").doc(coupleId);
    const coupleSnap = await coupleRef.get();
    if (!coupleSnap.exists) {
      throw new HttpsError("not-found", "Couple not found.");
    }
    const memberIds = Array.isArray(coupleSnap.get("memberIds")) ?
      coupleSnap.get("memberIds") : [];
    if (!memberIds.includes(uid)) {
      throw new HttpsError("permission-denied", "Not a member of this couple.");
    }
    const partnerUid = memberIds.find((id) => id !== uid) || null;
    if (!partnerUid) {
      return {ok: false, reason: "no_partner"};
    }

    const markerRef = coupleRef.collection("dailyAnswers").doc(date);

    try {
      // 1. Idempotent: someone (the partner's phone, or an earlier call) has
      //    already fixed today's question -> hand back exactly that text.
      const existing = await markerRef.get();
      const existingVi = `${existing.get("questionVi") || ""}`.trim();
      const existingEn = `${existing.get("questionEn") || ""}`.trim();
      if (existingVi && existingEn) {
        return {
          ok: true,
          questionVi: existingVi,
          questionEn: existingEn,
          source: `${existing.get("source") || "bank"}`,
        };
      }

      // 2. Opt-in gate + key availability.
      const prefsSnap = await coupleRef.collection("prefs").doc("home").get();
      if (prefsSnap.get("aiQuestionsEnabled") !== true) {
        return {ok: false, reason: "disabled"};
      }
      const apiKey = `${ANTHROPIC_API_KEY.value() || ""}`.trim();
      if (!apiKey || apiKey === "unset") {
        return {ok: false, reason: "no_api_key"};
      }

      // Rate limit: count attempts on the day's marker (Admin write; `date` is
      // included so the doc still lists correctly for clients).
      const attempts = await db.runTransaction(async (tx) => {
        const snap = await tx.get(markerRef);
        const n = Number((snap.exists && snap.get("aiAttempts")) || 0) + 1;
        tx.set(markerRef, {date, aiAttempts: n}, {merge: true});
        return n;
      });
      if (attempts > AI_MAX_ATTEMPTS_PER_DAY) {
        logger.warn("generateDailyQuestion: rate limited.", {coupleId, date, attempts});
        return {ok: false, reason: "rate_limited"};
      }

      // 3. Build the (anonymised) context.
      const markersSnap = await coupleRef
        .collection("dailyAnswers")
        .orderBy("date", "desc")
        .limit(60)
        .get();

      const answeredDays = [];
      const askedQuestions = [];
      const answeredDates = new Set();
      for (const markerDoc of markersSnap.docs) {
        const markerDate = `${markerDoc.get("date") || markerDoc.id}`;
        if (markerDate >= date) {
          continue; // today / future days carry no reveal yet
        }
        const question = aiTrim(markerDoc.get("questionVi"), 200);
        if (question && askedQuestions.length < 60) {
          askedQuestions.push(question);
        }
        if (markerDoc.get("bothAnswered") !== true) {
          continue;
        }
        answeredDates.add(markerDate);
        if (answeredDays.length < 30) {
          answeredDays.push({date: markerDate, question, ref: markerDoc.ref});
        }
      }

      // Pull each day's two answers (≤2 docs per day).
      await Promise.all(answeredDays.map(async (day) => {
        const responses = await day.ref.collection("responses").limit(2).get();
        day.answers = responses.docs.map((responseDoc) => ({
          who: responseDoc.id === uid ? "A" : "B",
          text: aiTrim(responseDoc.get("text"), 240),
        })).filter((entry) => entry.text);
      }));

      // Streak = consecutive fully-answered days walking back from yesterday.
      let streak = 0;
      let cursor = aiShiftDate(date, -1);
      while (answeredDates.has(cursor) && streak < 400) {
        streak += 1;
        cursor = aiShiftDate(cursor, -1);
      }

      // Days together (from the anniversary), if the couple set one.
      const anniversary = aiAnniversaryDateKey(coupleSnap.get("anniversaryDate"));
      const daysTogether = anniversary ?
        Math.round((aiDateToUtcMs(date) - aiDateToUtcMs(anniversary)) / 86400000) :
        null;

      // Today's moods (only when the mood doc is for the same day).
      const moodSnaps = await Promise.all([
        coupleRef.collection("moods").doc(uid).get(),
        coupleRef.collection("moods").doc(partnerUid).get(),
      ]);
      const moodOf = (snap) => (`${snap.get("date") || ""}` === date ?
        aiTrim(snap.get("mood"), 20) : "");
      const moodA = moodOf(moodSnaps[0]);
      const moodB = moodOf(moodSnaps[1]);

      const weekdayVi = AI_WEEKDAY_VI[new Date(aiDateToUtcMs(date)).getUTCDay()];

      const contextLines = [
        `Hôm nay: ${date} (${weekdayVi}).`,
        `Ngôn ngữ chính người dùng đang đọc: ${lang === "en" ? "tiếng Anh" : "tiếng Việt"}.`,
      ];
      if (daysTogether != null && daysTogether > 0) {
        contextLines.push(`Số ngày hai người đã bên nhau: ${daysTogether}.`);
      }
      contextLines.push(`Chuỗi ngày cùng trả lời hiện tại: ${streak}.`);
      if (moodA || moodB) {
        contextLines.push(
          `Tâm trạng hôm nay — A: ${moodA || "chưa chọn"}; B: ${moodB || "chưa chọn"}.`,
        );
      }
      if (answeredDays.length) {
        contextLines.push("", "Các ngày gần đây (mới nhất trước), A và B là hai người trong cặp:");
        for (const day of answeredDays) {
          contextLines.push(`• ${day.date} — hỏi: ${day.question || "(không rõ)"}`);
          for (const entry of day.answers || []) {
            contextLines.push(`   ${entry.who}: ${entry.text}`);
          }
        }
      } else {
        contextLines.push("", "Chưa có ngày nào cả hai cùng trả lời — hãy hỏi một câu dễ mở lời.");
      }
      if (askedQuestions.length) {
        contextLines.push("", "Các câu hỏi đã dùng gần đây (TUYỆT ĐỐI không lặp lại):");
        for (const question of askedQuestions) {
          contextLines.push(`- ${question}`);
        }
      }
      contextLines.push("", "Hãy viết câu hỏi cho hôm nay.");

      // 4. Ask Claude for one question (structured JSON output).
      const client = new Anthropic({apiKey});
      const response = await client.messages.create({
        model: AI_QUESTION_MODEL,
        max_tokens: 1024,
        output_config: {
          effort: "low",
          format: {type: "json_schema", schema: AI_QUESTION_SCHEMA},
        },
        system: AI_QUESTION_SYSTEM_PROMPT,
        messages: [{role: "user", content: contextLines.join("\n")}],
      });

      if (response.usage) {
        logger.info("generateDailyQuestion: model usage.", {
          coupleId,
          date,
          model: AI_QUESTION_MODEL,
          inputTokens: response.usage.input_tokens,
          outputTokens: response.usage.output_tokens,
        });
      }
      if (response.stop_reason === "refusal") {
        return {ok: false, reason: "refusal"};
      }

      const textBlock = (response.content || []).find((b) => b.type === "text");
      const raw = (textBlock && textBlock.text) || "";
      let parsed;
      try {
        parsed = JSON.parse(raw);
      } catch (_) {
        logger.warn("generateDailyQuestion: model output was not JSON.", {
          coupleId, date, sample: raw.slice(0, 200),
        });
        return {ok: false, reason: "invalid"};
      }

      // 5. Validate before it can ever reach a card.
      const questionVi = `${(parsed && parsed.vi) || ""}`.trim();
      const questionEn = `${(parsed && parsed.en) || ""}`.trim();
      const shapeOk = (text) => text.length >= 10 &&
        text.length <= 220 &&
        !/[{}<>]/.test(text);
      const recent = new Set(askedQuestions.map((q) => q.toLowerCase()));
      if (!shapeOk(questionVi) || !shapeOk(questionEn) ||
          recent.has(questionVi.toLowerCase())) {
        logger.warn("generateDailyQuestion: rejected model output.", {
          coupleId, date, viLength: questionVi.length, enLength: questionEn.length,
        });
        return {ok: false, reason: "invalid"};
      }

      // 6. Commit into the marker — but only if nobody beat us to it. If the
      //    other phone wrote a question meanwhile, return THEIRS so both sides
      //    still see one identical question for the day.
      const committed = await db.runTransaction(async (tx) => {
        const snap = await tx.get(markerRef);
        const already = `${snap.get("questionVi") || ""}`.trim();
        const alreadyEn = `${snap.get("questionEn") || ""}`.trim();
        if (already && alreadyEn) {
          return {
            questionVi: already,
            questionEn: alreadyEn,
            source: `${snap.get("source") || "bank"}`,
          };
        }
        tx.set(markerRef, {
          date,
          questionVi,
          questionEn,
          source: "ai",
          aiModel: AI_QUESTION_MODEL,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        return {questionVi, questionEn, source: "ai"};
      });

      return {ok: true, ...committed};
    } catch (err) {
      // Fail-soft on purpose: the client falls back to the local engine.
      logger.error("generateDailyQuestion failed.", {
        coupleId,
        date,
        message: err && err.message,
      });
      return {ok: false, reason: "error"};
    }
  },
);
