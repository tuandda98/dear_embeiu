const { doc, setDoc } = require('firebase/firestore');
const {
  assertSucceeds,
  authedDb,
  validCouple,
  validUser,
  validDevice,
} = require('./helpers');

// These simulate the OLD (1.0) app, which omits fields that 1.1 added
// (coupleCode, languageCode, sessionToken). There is ONE shared prod backend
// serving both versions at once, so the rules MUST still accept writes that
// lack these newer OPTIONAL keys — otherwise deploying the rules instantly
// breaks users who haven't updated yet (permission-denied on a write they did
// nothing wrong on).
//
// Rule of thumb proven here: an optional key must be read with
// `data.get('key', null)` (absent → null → valid), NEVER `data.key` (absent →
// "Property ... is undefined" error → the whole rule denies).
describe('firestore: backward-compatibility with the OLD (1.0) app', () => {
  it('accepts a couple created WITHOUT coupleCode (old app omits it)', async () => {
    const c = validCouple({ memberIds: ['alice'] });
    delete c.coupleCode;
    await assertSucceeds(setDoc(doc(authedDb('alice'), 'couples/c1'), c));
  });

  it('accepts a user created WITHOUT sessionToken (old app omits it)', async () => {
    const u = validUser();
    delete u.sessionToken; // already absent in the factory; explicit for intent
    await assertSucceeds(setDoc(doc(authedDb('alice'), 'users/alice'), u));
  });

  it('accepts a device registered WITHOUT languageCode (old app omits it)', async () => {
    const d = validDevice();
    delete d.languageCode;
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'users/alice/devices/d1'), d),
    );
  });
});
