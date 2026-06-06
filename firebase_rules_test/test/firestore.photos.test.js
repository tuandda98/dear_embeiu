const { doc, setDoc, getDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  seedDoc,
  seedActiveCouple,
  validPhoto,
  TS,
} = require('./helpers');

describe('firestore: /couples/{id}/photos/{photoId}', () => {
  beforeEach(async () => {
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  describe('create', () => {
    it('lets a member post a photo they authored', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), 'couples/c1/photos/p1'), validPhoto('c1', 'alice')),
      );
    });

    it('lets the OTHER member post too', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('bob'), 'couples/c1/photos/p1'), validPhoto('c1', 'bob')),
      );
    });

    it('forbids posting a photo attributed to someone else', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), 'couples/c1/photos/p1'), validPhoto('c1', 'bob')),
      );
    });

    it('forbids a non-member posting', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), 'couples/c1/photos/p1'), validPhoto('c1', 'dave')),
      );
    });

    it('rejects a coupleId that does not match the path', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/photos/p1'),
          validPhoto('c1', 'alice', { coupleId: 'other' }),
        ),
      );
    });

    it('rejects an extra (non-whitelisted) field', async () => {
      await assertFails(
        setDoc(
          doc(authedDb('alice'), 'couples/c1/photos/p1'),
          validPhoto('c1', 'alice', { secret: true }),
        ),
      );
    });

    it('rejects a missing uploadDate', async () => {
      const p = validPhoto('c1', 'alice');
      delete p.uploadDate;
      await assertFails(setDoc(doc(authedDb('alice'), 'couples/c1/photos/p1'), p));
    });
  });

  describe('read', () => {
    beforeEach(async () => {
      await seedDoc('couples/c1/photos/p1', validPhoto('c1', 'alice'));
    });

    it('lets a member read a photo', async () => {
      await assertSucceeds(getDoc(doc(authedDb('bob'), 'couples/c1/photos/p1')));
    });

    it('forbids a non-member reading a photo', async () => {
      await assertFails(getDoc(doc(authedDb('dave'), 'couples/c1/photos/p1')));
    });
  });

  describe('update', () => {
    beforeEach(async () => {
      await seedDoc('couples/c1/photos/p1', validPhoto('c1', 'alice'));
    });

    it('lets a member edit the caption', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), 'couples/c1/photos/p1'), { caption: 'new caption' }),
      );
    });

    it('forbids changing the immutable authorUserId', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1/photos/p1'), { authorUserId: 'bob' }),
      );
    });

    it('forbids changing the immutable uploadDate', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), 'couples/c1/photos/p1'), {
          uploadDate: new Date('2030-01-01'),
        }),
      );
    });
  });

  describe('delete', () => {
    beforeEach(async () => {
      await seedDoc('couples/c1/photos/p1', validPhoto('c1', 'alice'));
    });

    it('lets any member delete a photo (delete is membership-gated, not author-gated)', async () => {
      await assertSucceeds(deleteDoc(doc(authedDb('bob'), 'couples/c1/photos/p1')));
    });

    it('forbids a non-member deleting a photo', async () => {
      await assertFails(deleteDoc(doc(authedDb('dave'), 'couples/c1/photos/p1')));
    });
  });

  describe('reactions /couples/{id}/photos/{photoId}/reactions/{uid}', () => {
    const path = 'couples/c1/photos/p1/reactions';
    const reaction = (overrides = {}) => ({
      authorUserId: 'alice',
      coupleId: 'c1',
      emoji: '❤️',
      reactedAt: TS,
      ...overrides,
    });

    it('lets a member react with an allowed emoji', async () => {
      await assertSucceeds(setDoc(doc(authedDb('alice'), `${path}/alice`), reaction()));
    });

    it("forbids reacting under another member's uid", async () => {
      await assertFails(setDoc(doc(authedDb('alice'), `${path}/bob`), reaction()));
    });

    it('forbids spoofing authorUserId', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), `${path}/alice`), reaction({ authorUserId: 'bob' })),
      );
    });

    it('rejects an emoji outside the allowed set', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), `${path}/alice`), reaction({ emoji: '💩' })),
      );
    });

    it('rejects a coupleId that does not match the path', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), `${path}/alice`), reaction({ coupleId: 'other' })),
      );
    });

    it('forbids a non-member reacting', async () => {
      await assertFails(
        setDoc(doc(authedDb('dave'), `${path}/dave`), reaction({ authorUserId: 'dave' })),
      );
    });

    it('lets a member delete their own reaction but not the partner one', async () => {
      await seedDoc(`${path}/alice`, reaction());
      await seedDoc(`${path}/bob`, reaction({ authorUserId: 'bob' }));
      await assertSucceeds(deleteDoc(doc(authedDb('alice'), `${path}/alice`)));
      await assertFails(deleteDoc(doc(authedDb('alice'), `${path}/bob`)));
    });
  });
});
