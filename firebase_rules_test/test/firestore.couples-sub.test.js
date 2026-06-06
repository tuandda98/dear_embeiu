const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
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
