const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  seedDoc,
  seedActiveCouple,
  TS,
} = require('./helpers');

const tooLong = (n) => 'a'.repeat(n);

describe('firestore: couple subcollections', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  describe('/couples/{id}/prefs/home (shared home prefs — counter bg)', () => {
    it('lets a member set the shared counter background', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          counterBgPhotoId: 'photo-123',
        }),
      );
    });

    it('lets the partner read it', async () => {
      await seedDoc('couples/c1/prefs/home', { counterBgPhotoId: 'photo-123' });
      await assertSucceeds(
        getDoc(doc(authedDb('bob'), 'couples/c1/prefs/home')),
      );
    });

    it('denies an outsider reading or writing', async () => {
      await assertFails(
        getDoc(doc(authedDb('dave'), 'couples/c1/prefs/home')),
      );
      await assertFails(
        setDoc(doc(authedDb('dave'), 'couples/c1/prefs/home'), {
          counterBgPhotoId: 'photo-123',
        }),
      );
    });

    it('denies extra fields, wrong doc id, and oversized values', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          counterBgPhotoId: 'photo-123',
          sneaky: true,
        }),
      );
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/other'), {
          counterBgPhotoId: 'photo-123',
        }),
      );
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          counterBgPhotoId: tooLong(201),
        }),
      );
    });

    it('lets a member set the background whitelist (counterBgPhotoIds)', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          counterBgPhotoIds: ['photo-1', 'photo-2', 'couple'],
        }),
      );
    });

    it('lets the selected photo + whitelist coexist', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          counterBgPhotoId: 'photo-1',
          counterBgPhotoIds: ['photo-1', 'photo-2'],
        }),
      );
    });

    it('denies an oversized whitelist (>60)', async () => {
      const big = Array.from({ length: 61 }, (_, i) => `p${i}`);
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          counterBgPhotoIds: big,
        }),
      );
    });

    it('lets a member set the chat background (and clear it with "")', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          chatBgPhotoId: 'photo-9',
        }),
      );
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          chatBgPhotoId: '',
        }),
      );
    });

    it('denies an oversized chat background id (>200)', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/prefs/home'), {
          chatBgPhotoId: tooLong(201),
        }),
      );
    });
  });

  describe('/couples/{id}/notes/{noteId} (latest love note, doc id == author)', () => {
    it('lets a member write their own note', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/notes/alice'), {
          authorUserId: 'alice',
          text: 'love you',
          updatedAt: TS,
        }),
      );
    });

    it('forbids writing a note under another uid', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/notes/bob'), {
          authorUserId: 'alice',
          text: 'x',
        }),
      );
    });

    it('forbids spoofing authorUserId', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/notes/alice'), {
          authorUserId: 'bob',
          text: 'x',
        }),
      );
    });

    it('rejects text longer than 140 chars', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/notes/alice'), {
          authorUserId: 'alice',
          text: tooLong(141),
        }),
      );
    });

    it('forbids a non-member writing a note', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), 'couples/c1/notes/dave'), {
          authorUserId: 'dave',
          text: 'x',
        }),
      );
    });

    it('lets a member read the partner note; forbids outsiders', async () => {
      await seedDoc('couples/c1/notes/alice', { authorUserId: 'alice', text: 'hi' });
      await assertSucceeds(getDoc(doc(authedDb('bob'), 'couples/c1/notes/alice')));
      await assertFails(getDoc(doc(authedDb('dave'), 'couples/c1/notes/alice')));
    });
  });

  describe('/couples/{id}/noteHistory/{entryId} (append-only archive)', () => {
    it('lets a member append their own entry', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/noteHistory/e1'), {
          authorUserId: 'alice',
          text: 'first note',
          createdAt: TS,
        }),
      );
    });

    it('rejects an empty entry', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/noteHistory/e1'), {
          authorUserId: 'alice',
          text: '',
        }),
      );
    });

    it('forbids spoofing authorUserId', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/noteHistory/e1'), {
          authorUserId: 'bob',
          text: 'x',
        }),
      );
    });

    it('is immutable: no update, no delete', async () => {
      await seedDoc('couples/c1/noteHistory/e1', { authorUserId: 'alice', text: 'x' });
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1/noteHistory/e1'), { text: 'edited' }),
      );
      await assertFails(deleteDoc(doc(authedDb('alice'), 'couples/c1/noteHistory/e1')));
    });
  });

  describe('/couples/{id}/messages/{messageId} (couple chat — feature chat D2/D3)', () => {
    // The rule requires createdAt == request.time → only serverTimestamp()
    // passes (exactly what the app sends).
    const validMessage = (uid, overrides = {}) => ({
      authorUserId: uid,
      text: 'hello you',
      createdAt: serverTimestamp(),
      ...overrides,
    });

    it('lets a member send their own message', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/messages/m1'), validMessage('alice')),
      );
    });

    it('accepts text at exactly 1000 chars', async () => {
      await assertSucceeds(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/messages/m1'),
          validMessage('alice', { text: tooLong(1000) }),
        ),
      );
    });

    it('rejects text over 1000 chars', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/messages/m1'),
          validMessage('alice', { text: tooLong(1001) }),
        ),
      );
    });

    it('rejects an empty message', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/messages/m1'),
          validMessage('alice', { text: '' }),
        ),
      );
    });

    it('forbids spoofing authorUserId', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/messages/m1'),
          validMessage('bob'),
        ),
      );
    });

    it('rejects extra fields', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/messages/m1'),
          validMessage('alice', { sneaky: true }),
        ),
      );
    });

    it('rejects a client-fixed createdAt (must be request.time)', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/messages/m1'),
          validMessage('alice', { createdAt: TS }),
        ),
      );
    });

    it('forbids a non-member sending or reading', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), 'couples/c1/messages/m1'), validMessage('dave')),
      );
      await seedDoc('couples/c1/messages/m1', { authorUserId: 'alice', text: 'hi', createdAt: TS });
      await assertFails(getDoc(doc(authedDb('dave'), 'couples/c1/messages/m1')));
    });

    it('lets the partner read a message', async () => {
      await seedDoc('couples/c1/messages/m1', { authorUserId: 'alice', text: 'hi', createdAt: TS });
      await assertSucceeds(getDoc(doc(authedDb('bob'), 'couples/c1/messages/m1')));
    });

    it('is immutable: no update, no delete (even by the author)', async () => {
      await seedDoc('couples/c1/messages/m1', { authorUserId: 'alice', text: 'hi', createdAt: TS });
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1/messages/m1'), { text: 'edited' }),
      );
      await assertFails(deleteDoc(doc(authedDb('alice'), 'couples/c1/messages/m1')));
      await assertFails(deleteDoc(doc(authedDb('bob'), 'couples/c1/messages/m1')));
    });
  });

  describe('/couples/{id}/receipts/{uid} (chat read/delivery receipts)', () => {
    it('lets a member write their OWN receipt (delivered + read)', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/receipts/alice'), {
          deliveredAt: serverTimestamp(),
          readAt: serverTimestamp(),
        }),
      );
    });

    it('lets a member write just one field (merge)', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('bob'), 'couples/c1/receipts/bob'), {
          readAt: serverTimestamp(),
        }),
      );
    });

    it('lets the partner read the receipt', async () => {
      await seedDoc('couples/c1/receipts/alice', { readAt: TS });
      await assertSucceeds(
        getDoc(doc(authedDb('bob'), 'couples/c1/receipts/alice')),
      );
    });

    it('forbids writing the partner\'s receipt (id must == uid)', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/receipts/bob'), {
          readAt: serverTimestamp(),
        }),
      );
    });

    it('rejects extra fields and non-timestamp values', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/receipts/alice'), {
          readAt: serverTimestamp(),
          sneaky: true,
        }),
      );
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/receipts/alice'), {
          readAt: 'nope',
        }),
      );
    });

    it('forbids an outsider reading or writing', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), 'couples/c1/receipts/dave'), {
          readAt: serverTimestamp(),
        }),
      );
      await seedDoc('couples/c1/receipts/alice', { readAt: TS });
      await assertFails(
        getDoc(doc(authedDb('dave'), 'couples/c1/receipts/alice')),
      );
    });
  });

  describe('/couples/{id}/nudges/{nudgeId} (partner nudge — feature partner-nudge)', () => {
    // Same create-only shape as messages: createdAt must be request.time.
    const validNudge = (uid, overrides = {}) => ({
      authorUserId: uid,
      text: 'Nhớ uống nước',
      createdAt: serverTimestamp(),
      ...overrides,
    });

    it('lets a member send their own nudge', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1'), validNudge('alice')),
      );
    });

    it('accepts text at exactly 200 chars; rejects over 200', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1'),
          validNudge('alice', { text: tooLong(200) })),
      );
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/nudges/n2'),
          validNudge('alice', { text: tooLong(201) })),
      );
    });

    it('rejects an empty nudge', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1'),
          validNudge('alice', { text: '' })),
      );
    });

    it('forbids spoofing authorUserId', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1'), validNudge('bob')),
      );
    });

    it('rejects extra fields', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1'),
          validNudge('alice', { sneaky: true })),
      );
    });

    it('rejects a client-fixed createdAt (must be request.time)', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1'),
          validNudge('alice', { createdAt: TS })),
      );
    });

    it('forbids a non-member sending or reading', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), 'couples/c1/nudges/n1'), validNudge('dave')),
      );
      await seedDoc('couples/c1/nudges/n1', { authorUserId: 'alice', text: 'hi', createdAt: TS });
      await assertFails(getDoc(doc(authedDb('dave'), 'couples/c1/nudges/n1')));
    });

    it('lets the partner read a nudge', async () => {
      await seedDoc('couples/c1/nudges/n1', { authorUserId: 'alice', text: 'hi', createdAt: TS });
      await assertSucceeds(getDoc(doc(authedDb('bob'), 'couples/c1/nudges/n1')));
    });

    it('is immutable: no update, no delete', async () => {
      await seedDoc('couples/c1/nudges/n1', { authorUserId: 'alice', text: 'hi', createdAt: TS });
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1'), { text: 'edited' }),
      );
      await assertFails(deleteDoc(doc(authedDb('alice'), 'couples/c1/nudges/n1')));
    });
  });

  describe('/couples/{id}/partnerReminders/{id} (scheduled reminder for partner)', () => {
    const validReminder = (uid, overrides = {}) => ({
      authorUserId: uid,
      text: 'uống thuốc',
      minuteOfDay: 600,
      recurrence: 'daily',
      enabled: true,
      createdAt: serverTimestamp(),
      ...overrides,
    });

    it('lets a member create a reminder for their partner', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1'),
          validReminder('alice')),
      );
    });

    it('forbids spoofing authorUserId on create', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1'),
          validReminder('bob')),
      );
    });

    it('rejects empty/oversized text', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1'),
          validReminder('alice', { text: '' })),
      );
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r2'),
          validReminder('alice', { text: tooLong(201) })),
      );
    });

    it('rejects minuteOfDay out of range', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1'),
          validReminder('alice', { minuteOfDay: 1440 })),
      );
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r2'),
          validReminder('alice', { minuteOfDay: -1 })),
      );
    });

    it('rejects a client-fixed createdAt', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1'),
          validReminder('alice', { createdAt: TS })),
      );
    });

    it('lets the partner read it; outsider cannot', async () => {
      await seedDoc('couples/c1/partnerReminders/r1',
        { authorUserId: 'alice', text: 'x', minuteOfDay: 600, recurrence: 'daily', enabled: true });
      await assertSucceeds(getDoc(doc(authedDb('bob'), 'couples/c1/partnerReminders/r1')));
      await assertFails(getDoc(doc(authedDb('dave'), 'couples/c1/partnerReminders/r1')));
    });

    it('lets ONLY the author update; forbids the partner', async () => {
      await seedDoc('couples/c1/partnerReminders/r1',
        { authorUserId: 'alice', text: 'x', minuteOfDay: 600, recurrence: 'daily', enabled: true });
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1'), { enabled: false }),
      );
      await assertFails(
        updateDoc(doc(authedDb('bob'), 'couples/c1/partnerReminders/r1'), { enabled: false }),
      );
    });

    it('forbids changing authorUserId on update', async () => {
      await seedDoc('couples/c1/partnerReminders/r1',
        { authorUserId: 'alice', text: 'x', minuteOfDay: 600, recurrence: 'daily', enabled: true });
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1'),
          { authorUserId: 'bob' }),
      );
    });

    it('lets ONLY the author delete; forbids the partner', async () => {
      await seedDoc('couples/c1/partnerReminders/r1',
        { authorUserId: 'alice', text: 'x', minuteOfDay: 600, recurrence: 'daily', enabled: true });
      await assertFails(
        deleteDoc(doc(authedDb('bob'), 'couples/c1/partnerReminders/r1')),
      );
      await assertSucceeds(
        deleteDoc(doc(authedDb('alice'), 'couples/c1/partnerReminders/r1')),
      );
    });

    it('forbids a non-member creating', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), 'couples/c1/partnerReminders/r1'),
          validReminder('dave')),
      );
    });
  });

  describe('/couples/{id}/dailyAnswers/{date} (question-text marker)', () => {
    const path = 'couples/c1/dailyAnswers/2026-01-01';

    it('lets a member write the marker with question snapshots', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), path), {
          date: '2026-01-01',
          questionVi: 'Câu hỏi hôm nay?',
          questionEn: 'Question today?',
          updatedAt: TS,
        }),
      );
    });

    it('rejects a missing question field', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), path), {
          date: '2026-01-01',
          questionVi: 'Câu hỏi?',
        }),
      );
    });

    it('rejects a question string over 300 chars', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), path), {
          date: '2026-01-01',
          questionVi: tooLong(301),
          questionEn: 'ok',
        }),
      );
    });

    it('forbids a non-member writing the marker', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), path), {
          date: '2026-01-01',
          questionVi: 'x',
          questionEn: 'y',
        }),
      );
    });
  });

  describe('/couples/{id}/dailyAnswers/{date}/responses/{uid}', () => {
    const base = 'couples/c1/dailyAnswers/2026-01-01/responses';

    it('lets a member write their own answer', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), `${base}/alice`), {
          authorUserId: 'alice',
          text: 'my answer',
          answeredAt: TS,
        }),
      );
    });

    it("forbids writing under another member's uid", async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), `${base}/bob`), {
          authorUserId: 'alice',
          text: 'x',
        }),
      );
    });

    it('forbids spoofing authorUserId', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), `${base}/alice`), {
          authorUserId: 'bob',
          text: 'x',
        }),
      );
    });

    it('rejects an answer over 280 chars', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), `${base}/alice`), {
          authorUserId: 'alice',
          text: tooLong(281),
        }),
      );
    });

    it('lets a member read the partner answer (reveal is client-side only)', async () => {
      await seedDoc(`${base}/alice`, { authorUserId: 'alice', text: 'hi' });
      await assertSucceeds(getDoc(doc(authedDb('bob'), `${base}/alice`)));
      await assertFails(getDoc(doc(authedDb('dave'), `${base}/alice`)));
    });
  });
});
