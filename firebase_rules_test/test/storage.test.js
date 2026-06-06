const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');
const {
  assertSucceeds,
  assertFails,
  authedStorage,
  unauthedStorage,
  seedActiveCouple,
} = require('./helpers');

// A tiny valid PNG-ish payload; rules only check contentType + size, not bytes.
const smallImage = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const imageMeta = { contentType: 'image/png' };

const OBJECT = 'couple_photos/c1/photo.png';

describe('storage: /couple_photos/{coupleId}/{fileName}', () => {
  beforeEach(async () => {
    // Membership is resolved cross-service from Firestore, so seed the couple.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  describe('create / upload', () => {
    it('lets a member upload an image under their couple', async () => {
      const r = ref(authedStorage('alice'), OBJECT);
      await assertSucceeds(uploadBytes(r, smallImage, imageMeta));
    });

    it('forbids a non-member uploading', async () => {
      const r = ref(authedStorage('dave'), OBJECT);
      await assertFails(uploadBytes(r, smallImage, imageMeta));
    });

    it('forbids an unauthenticated upload', async () => {
      const r = ref(unauthedStorage(), OBJECT);
      await assertFails(uploadBytes(r, smallImage, imageMeta));
    });

    it('rejects a non-image content type', async () => {
      const r = ref(authedStorage('alice'), OBJECT);
      await assertFails(uploadBytes(r, smallImage, { contentType: 'text/plain' }));
    });

    it('rejects an oversized (>10MB) upload', async () => {
      const big = new Uint8Array(10 * 1024 * 1024 + 1);
      const r = ref(authedStorage('alice'), OBJECT);
      await assertFails(uploadBytes(r, big, imageMeta));
    });
  });

  describe('read / delete', () => {
    beforeEach(async () => {
      // Upload as a member first (allowed), so there is an object to read/delete.
      await uploadBytes(ref(authedStorage('alice'), OBJECT), smallImage, imageMeta);
    });

    it('lets a member read the object', async () => {
      await assertSucceeds(getBytes(ref(authedStorage('bob'), OBJECT)));
    });

    it('forbids a non-member reading the object', async () => {
      await assertFails(getBytes(ref(authedStorage('dave'), OBJECT)));
    });

    it('lets a member delete the object', async () => {
      await assertSucceeds(deleteObject(ref(authedStorage('bob'), OBJECT)));
    });

    it('forbids a non-member deleting the object', async () => {
      await assertFails(deleteObject(ref(authedStorage('dave'), OBJECT)));
    });
  });
});
