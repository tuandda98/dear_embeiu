// Weather city rules (feature weather, overview §5.2) —
// couples/{coupleId}/weather/{uid} = { cityId, setBy, updatedAt }.
// One doc per member; both read; the owner always writes theirs; the partner
// may pick for them only while the owner hasn't picked their own (D6).
// weatherCache/{cityId} has no rule ⇒ clients are locked out.

const {
  doc,
  setDoc,
  getDoc,
  deleteDoc,
  serverTimestamp,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  unauthedDb,
  seedDoc,
  seedActiveCouple,
  seedWaitingCouple,
  TS,
} = require('./helpers');

describe('firestore: weather city', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; waiting couple cw = {carol}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
    await seedWaitingCouple('cw', 'carol');
  });

  const pick = (by, cityId = 'vn-ha-noi', extra = {}) => ({
    cityId,
    setBy: by,
    updatedAt: serverTimestamp(),
    ...extra,
  });
  const write = (asUid, ownerUid, data, couple = 'c1') =>
    setDoc(doc(authedDb(asUid), `couples/${couple}/weather/${ownerUid}`), data);

  it('lets a member pick their own city', async () => {
    await assertSucceeds(write('alice', 'alice', pick('alice')));
  });

  it('lets a member read the partner city', async () => {
    await seedDoc('couples/c1/weather/bob', { cityId: 'vn-tp-hcm', setBy: 'bob', updatedAt: TS });
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'couples/c1/weather/bob')));
  });

  it('lets a member pick for the partner when the partner has none yet', async () => {
    await assertSucceeds(write('alice', 'bob', pick('alice', 'vn-tp-hcm')));
  });

  it('lets a member change a city they picked for the partner', async () => {
    await seedDoc('couples/c1/weather/bob', { cityId: 'vn-tp-hcm', setBy: 'alice', updatedAt: TS });
    await assertSucceeds(write('alice', 'bob', pick('alice', 'vn-da-lat')));
  });

  it('forbids overwriting a city the partner picked themselves', async () => {
    await seedDoc('couples/c1/weather/bob', { cityId: 'vn-da-lat', setBy: 'bob', updatedAt: TS });
    await assertFails(write('alice', 'bob', pick('alice', 'vn-tp-hcm')));
  });

  it('lets the owner override a city the partner picked for them', async () => {
    await seedDoc('couples/c1/weather/bob', { cityId: 'vn-tp-hcm', setBy: 'alice', updatedAt: TS });
    await assertSucceeds(write('bob', 'bob', pick('bob', 'vn-da-lat')));
  });

  it('forbids writing a doc for a uid outside the couple', async () => {
    await assertFails(write('alice', 'dave', pick('alice')));
  });

  it('forbids outsiders reading or writing', async () => {
    await seedDoc('couples/c1/weather/alice', { cityId: 'vn-ha-noi', setBy: 'alice', updatedAt: TS });
    await assertFails(getDoc(doc(authedDb('dave'), 'couples/c1/weather/alice')));
    await assertFails(write('dave', 'dave', pick('dave')));
    await assertFails(write('dave', 'alice', pick('dave')));
    await assertFails(getDoc(doc(unauthedDb(), 'couples/c1/weather/alice')));
  });

  it('forbids spoofing setBy', async () => {
    await assertFails(write('alice', 'bob', pick('bob', 'vn-tp-hcm')));
    await assertFails(write('alice', 'alice', pick('bob')));
  });

  it('requires updatedAt == request.time', async () => {
    await assertFails(write('alice', 'alice', { cityId: 'vn-ha-noi', setBy: 'alice', updatedAt: TS }));
    await assertFails(write('alice', 'alice', { cityId: 'vn-ha-noi', setBy: 'alice' }));
  });

  it('forbids extra keys (no name / coordinates stored)', async () => {
    await assertFails(write('alice', 'alice', pick('alice', 'vn-ha-noi', { lat: 21.03 })));
  });

  it('forbids an empty, over-long or odd-shaped cityId', async () => {
    for (const bad of ['', `vn-${'a'.repeat(38)}`, 'VN-HA-NOI', '../x', 'hanoi', 'vn_ha_noi', 42]) {
      await assertFails(write('alice', 'alice', pick('alice', bad)));
    }
    // 40 characters is the ceiling and still fine.
    await assertSucceeds(write('alice', 'alice', pick('alice', `vn-${'a'.repeat(37)}`)));
  });

  it('lets the owner delete their city, never the partner one', async () => {
    await seedDoc('couples/c1/weather/alice', { cityId: 'vn-ha-noi', setBy: 'alice', updatedAt: TS });
    await seedDoc('couples/c1/weather/bob', { cityId: 'vn-tp-hcm', setBy: 'alice', updatedAt: TS });
    await assertFails(deleteDoc(doc(authedDb('alice'), 'couples/c1/weather/bob')));
    await assertSucceeds(deleteDoc(doc(authedDb('alice'), 'couples/c1/weather/alice')));
  });

  it('while waiting for a partner: own city only', async () => {
    await assertSucceeds(write('carol', 'carol', pick('carol'), 'cw'));
    await assertFails(write('carol', 'erin', pick('carol'), 'cw'));
  });

  it('a member who left loses access; the doc they left behind is not theirs to keep', async () => {
    await seedDoc('couples/c1/weather/bob', { cityId: 'vn-tp-hcm', setBy: 'bob', updatedAt: TS });
    await seedWaitingCouple('c1', 'alice'); // bob left
    await assertFails(getDoc(doc(authedDb('bob'), 'couples/c1/weather/bob')));
    await assertFails(write('bob', 'bob', pick('bob')));
  });

  it('keeps weatherCache closed to every client', async () => {
    await seedDoc('weatherCache/vn-ha-noi', { cityId: 'vn-ha-noi', fetchedAt: 1, hours: [] });
    await assertFails(getDoc(doc(authedDb('alice'), 'weatherCache/vn-ha-noi')));
    await assertFails(setDoc(doc(authedDb('alice'), 'weatherCache/vn-ha-noi'), { hours: [] }));
    await assertFails(getDoc(doc(unauthedDb(), 'weatherCache/vn-ha-noi')));
  });

  it('older apps are unaffected: moods keep working next to weather docs', async () => {
    await seedDoc('couples/c1/weather/alice', { cityId: 'vn-ha-noi', setBy: 'alice', updatedAt: TS });
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'couples/c1/moods/alice'), {
        authorUserId: 'alice',
        mood: 'happy',
        date: '2026-10-20',
        updatedAt: TS,
      }),
    );
    await assertSucceeds(getDoc(doc(authedDb('bob'), 'couples/c1')));
  });
});
