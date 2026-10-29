// Feedback rules (feature feedback) — feedback/{id}: create-only cho user đã
// đăng nhập, payload pin chặt; client không đọc/sửa/xoá. Kèm storage
// feedback/{uid}/{file}.

const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');
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
  unauthedDb,
  authedStorage,
  unauthedStorage,
  seedDoc,
} = require('./helpers');

const PATH = 'feedback/f1';

const validFeedback = (uid, overrides = {}) => ({
  userId: uid,
  type: 'bug',
  message: 'Ảnh không tải lên được',
  appVersion: '1.12.0',
  buildNumber: 33,
  platform: 'android',
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('firestore: /feedback/{id}', () => {
  it('lets a signed-in user create valid feedback (required fields only)', async () => {
    await assertSucceeds(setDoc(doc(authedDb('alice'), PATH), validFeedback('alice')));
  });

  it('accepts every optional field', async () => {
    await assertSucceeds(
      setDoc(
        doc(authedDb('alice'), PATH),
        validFeedback('alice', {
          type: 'idea',
          stars: 2,
          screenshotPath: 'feedback/alice/a.png',
          osVersion: 'Android 15',
          deviceModel: 'Pixel 8',
          locale: 'vi',
          email: 'a@b.com',
        }),
      ),
    );
  });

  it('accepts a rating with empty message', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { type: 'rating', stars: 5, message: '' })),
    );
  });

  it('rejects empty message for non-rating types', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { message: '' })));
  });

  it('rejects unauthenticated create', async () => {
    await assertFails(setDoc(doc(unauthedDb(), PATH), validFeedback('alice')));
  });

  it('rejects creating on behalf of another uid', async () => {
    await assertFails(setDoc(doc(authedDb('bob'), PATH), validFeedback('alice')));
  });

  it('rejects message over 2000 chars (2000 is ok)', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { message: 'x'.repeat(2001) })),
    );
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { message: 'x'.repeat(2000) })),
    );
  });

  it('rejects unknown keys', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { admin: true })));
  });

  it('rejects unknown type', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { type: 'spam' })));
  });

  it('rejects stars out of range or wrong type', async () => {
    for (const stars of [6, 0, 2.5, '3']) {
      await assertFails(setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { stars })));
    }
  });

  it('rejects screenshotPath outside feedback/<uid>/', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { screenshotPath: 'feedback/bob/a.png' })),
    );
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { screenshotPath: 'couple_photos/c1/a.png' })),
    );
  });

  it('rejects bad platform and non-int buildNumber', async () => {
    await assertFails(setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { platform: 'web' })));
    await assertFails(setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { buildNumber: '33' })));
  });

  it('rejects client-supplied createdAt', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), PATH), validFeedback('alice', { createdAt: new Date() })),
    );
  });

  it('rejects missing required field', async () => {
    const { appVersion, ...rest } = validFeedback('alice');
    await assertFails(setDoc(doc(authedDb('alice'), PATH), rest));
  });

  it('forbids read / update / delete, even for the author', async () => {
    await seedDoc(PATH, { userId: 'alice', type: 'bug', message: 'x' });
    await assertFails(getDoc(doc(authedDb('alice'), PATH)));
    await assertFails(updateDoc(doc(authedDb('alice'), PATH), { message: 'y' }));
    await assertFails(deleteDoc(doc(authedDb('alice'), PATH)));
  });
});

describe('storage: /feedback/{uid}/{fileName}', () => {
  const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);
  const meta = { contentType: 'image/png' };
  const OBJECT = 'feedback/alice/shot.png';

  it('lets the owner upload an image', async () => {
    await assertSucceeds(uploadBytes(ref(authedStorage('alice'), OBJECT), png, meta));
  });

  it('forbids uploading into another uid folder', async () => {
    await assertFails(uploadBytes(ref(authedStorage('bob'), OBJECT), png, meta));
  });

  it('forbids unauthenticated upload', async () => {
    await assertFails(uploadBytes(ref(unauthedStorage(), OBJECT), png, meta));
  });

  it('rejects non-image and oversized uploads', async () => {
    await assertFails(uploadBytes(ref(authedStorage('alice'), OBJECT), png, { contentType: 'text/plain' }));
    await assertFails(
      uploadBytes(ref(authedStorage('alice'), OBJECT), new Uint8Array(10 * 1024 * 1024 + 1), meta),
    );
  });

  it('forbids read and delete, even for the owner', async () => {
    await uploadBytes(ref(authedStorage('alice'), OBJECT), png, meta);
    await assertFails(getBytes(ref(authedStorage('alice'), OBJECT)));
    await assertFails(deleteObject(ref(authedStorage('alice'), OBJECT)));
  });
});
