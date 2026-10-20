// Arrival rules (feature arrival, đợt 2 — overview §5).
//   couples/{coupleId}/arrival/{uid} — share flag, auto flag, ONE latest event.
// No address, coordinates or list of places ever reach the server (D2); no
// history (D3); sharing off = the owner deletes the doc (D11); the CF push
// bookkeeping (couples/{c}/arrivalPush/{uid}) is Admin-only, nobody reads it.

const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  deleteField,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  seedDoc,
  seedActiveCouple,
  seedWaitingCouple,
  validCouple,
  validDevice,
  TS,
} = require('./helpers');

const MIN = 60 * 1000;
const HOUR = 60 * MIN;

const PATH = (uid, couple = 'c1') => `couples/${couple}/arrival/${uid}`;

// A valid event that happened `minutesAgo` minutes ago (negative = future).
function event(overrides = {}, minutesAgo = 1) {
  return {
    place: 'home',
    type: 'enter',
    at: Timestamp.fromMillis(Date.now() - minutesAgo * MIN),
    battery: 12,
    source: 'auto',
    ...overrides,
  };
}

const gym = (over = {}) => event({ place: 'p1', name: 'Phòng gym', icon: 'gym', ...over });

const sharing = (last) => ({ share: true, auto: true, last, updatedAt: serverTimestamp() });

function write(uid, data, { as = uid, couple = 'c1' } = {}) {
  return setDoc(doc(authedDb(as), PATH(uid, couple)), data);
}

describe('firestore: arrival', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  // ---- read ------------------------------------------------------------------
  it('both members read; an outsider cannot', async () => {
    await seedDoc(PATH('alice'), { share: true, auto: true, last: event(), updatedAt: TS });
    await assertSucceeds(getDoc(doc(authedDb('bob'), PATH('alice'))));
    await assertSucceeds(getDoc(doc(authedDb('alice'), PATH('alice'))));
    await assertFails(getDoc(doc(authedDb('dave'), PATH('alice'))));
  });

  // ---- create ----------------------------------------------------------------
  it('accepts the minimal doc {share:false}', async () => {
    await assertSucceeds(write('alice', { share: false }));
  });

  it('accepts a Home arrival (no name, no icon)', async () => {
    await assertSucceeds(write('alice', sharing(event())));
  });

  it('accepts a custom place with name + icon (n/r letters are fine)', async () => {
    await assertSucceeds(write('alice', sharing(gym())));
    await assertSucceeds(write('bob', sharing(event({ place: 'p4', name: 'Trường', source: 'manual' }))));
  });

  it("forbids writing the partner's doc (fake uid)", async () => {
    await assertFails(write('bob', sharing(event()), { as: 'alice' }));
  });

  it('forbids an outsider writing into the couple', async () => {
    await assertFails(write('dave', { share: false }));
    await assertFails(write('dave', sharing(event())));
  });

  it('forbids `last` while sharing is off (D11)', async () => {
    await assertFails(write('alice', { share: false, last: event() }));
    await assertFails(write('alice', { last: event() })); // share absent = false
  });

  it('forbids a slot outside home/p1..p4', async () => {
    await assertFails(write('alice', sharing(gym({ place: 'p5' }))));
    await assertFails(write('alice', sharing(gym({ place: 'work' }))));
  });

  it('forbids a name or icon on Home', async () => {
    await assertFails(write('alice', sharing(event({ name: 'Nhà' }))));
    await assertFails(write('alice', sharing(event({ icon: 'pin' }))));
  });

  it('forbids a custom place without a usable name', async () => {
    const noName = gym();
    delete noName.name;
    await assertFails(write('alice', sharing(noName)));
    await assertFails(write('alice', sharing(gym({ name: '' }))));
    await assertFails(write('alice', sharing(gym({ name: '   ' }))));
    await assertFails(write('alice', sharing(gym({ name: 7 }))));
  });

  it('name: 24 units pass, 25 do not (UTF-16, emoji = 2)', async () => {
    await assertSucceeds(write('alice', sharing(gym({ name: 'a'.repeat(24) }))));
    await assertFails(write('alice', sharing(gym({ name: 'a'.repeat(25) }))));
    await assertSucceeds(write('alice', sharing(gym({ name: '🏋'.repeat(12) }))));
    await assertFails(write('alice', sharing(gym({ name: '🏋'.repeat(13) }))));
  });

  it('forbids a line break in the name', async () => {
    await assertFails(write('alice', sharing(gym({ name: 'Nhà\nmẹ' }))));
    await assertFails(write('alice', sharing(gym({ name: 'Nhà\rmẹ' }))));
  });

  it('forbids an unknown icon', async () => {
    await assertFails(write('alice', sharing(gym({ icon: 'beer' }))));
    await assertFails(write('alice', sharing(gym({ icon: '🏠' }))));
  });

  it('forbids addresses, coordinates or a place list — top level or in the event', async () => {
    await assertFails(write('alice', { ...sharing(event()), address: '12 Nguyễn Trãi' }));
    await assertFails(write('alice', { ...sharing(event()), places: ['home'] }));
    await assertFails(write('alice', { ...sharing(event()), lat: 21.0 }));
    await assertFails(write('alice', sharing(event({ lat: 21.0, lng: 105.8 }))));
    await assertFails(write('alice', sharing(event({ radius: 250 }))));
  });

  it('at: ≤ 5 minutes ahead, ≤ 12 hours old', async () => {
    await assertSucceeds(write('alice', sharing(event({}, -4))));
    await assertFails(write('alice', sharing(event({}, -10))));
    await assertSucceeds(write('alice', sharing(event({}, 11 * 60))));
    await assertFails(write('alice', sharing(event({}, 13 * 60))));
    await assertFails(write('alice', sharing(event({ at: '2026-10-20T22:58' }))));
  });

  it('battery: int 0..100 or absent', async () => {
    const noBattery = event();
    delete noBattery.battery;
    await assertSucceeds(write('alice', sharing(noBattery)));
    await assertSucceeds(write('alice', sharing(event({ battery: 0 }))));
    await assertFails(write('alice', sharing(event({ battery: 101 }))));
    await assertFails(write('alice', sharing(event({ battery: -1 }))));
    await assertFails(write('alice', sharing(event({ battery: '50' }))));
  });

  it('forbids an unknown type / source and a non-bool bounce', async () => {
    await assertFails(write('alice', sharing(event({ type: 'arrive' }))));
    await assertFails(write('alice', sharing(event({ source: 'remote' }))));
    await assertFails(write('alice', sharing(event({ bounce: 'yes' }))));
    await assertSucceeds(write('alice', sharing(event({ bounce: true, type: 'exit' }))));
  });

  it('forbids non-bool share / auto', async () => {
    await assertFails(write('alice', { share: 'true' }));
    await assertFails(write('alice', { share: false, auto: 1 }));
  });

  it('sharing ON is refused while the couple waits for a partner', async () => {
    await seedWaitingCouple('cw', 'carol');
    await assertFails(write('carol', sharing(event()), { couple: 'cw' }));
    await assertFails(write('carol', { share: true }, { couple: 'cw' }));
    await assertSucceeds(write('carol', { share: false }, { couple: 'cw' }));
  });

  it("forbids a client writing the CF's push bookkeeping", async () => {
    await assertFails(write('alice', { ...sharing(event()), lastPushAt: { home: TS } }));
    await assertFails(write('alice', { ...sharing(event()), pushCount: 0 }));
    await seedDoc(PATH('alice'), { share: true, auto: false, updatedAt: TS });
    await assertFails(updateDoc(doc(authedDb('alice'), PATH('alice')), { pushCount: 0 }));
    await assertFails(updateDoc(doc(authedDb('alice'), PATH('alice')), { pushDay: '2026-10-20' }));
    await assertFails(updateDoc(doc(authedDb('alice'), PATH('alice')), { 'lastPushAt.home': TS }));
  });

  // ---- update ----------------------------------------------------------------
  describe('update', () => {
    beforeEach(async () => {
      await seedDoc(PATH('alice'), {
        share: true,
        auto: true,
        last: event({}, 13 * 60), // older than 12 h
        updatedAt: TS,
      });
    });

    it('a new event passes', async () => {
      await assertSucceeds(
        setDoc(
          doc(authedDb('alice'), PATH('alice')),
          { share: true, auto: true, last: gym(), updatedAt: serverTimestamp() },
          { mergeFields: ['share', 'auto', 'last', 'updatedAt'] },
        ),
      );
    });

    it('flipping `auto` passes even when the stored event is old', async () => {
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), PATH('alice')), { auto: false, updatedAt: serverTimestamp() }),
      );
    });

    it('a new invalid event is still refused', async () => {
      await assertFails(
        updateDoc(doc(authedDb('alice'), PATH('alice')), { last: event({}, 13 * 60 + 5) }),
      );
      await assertFails(updateDoc(doc(authedDb('alice'), PATH('alice')), { last: gym({ name: '' }) }));
    });

    it('sharing off removes `last` in the same write (deleteField)', async () => {
      await assertSucceeds(
        setDoc(
          doc(authedDb('alice'), PATH('alice')),
          { share: false, auto: false, last: deleteField(), updatedAt: serverTimestamp() },
          { merge: true },
        ),
      );
      const snap = await getDoc(doc(authedDb('bob'), PATH('alice')));
      if (snap.data().last !== undefined) throw new Error('last still there');
    });

    it('sharing off while keeping `last` is refused', async () => {
      await assertFails(updateDoc(doc(authedDb('alice'), PATH('alice')), { share: false }));
    });

    it('the partner cannot touch it', async () => {
      await assertFails(updateDoc(doc(authedDb('bob'), PATH('alice')), { auto: false }));
      await assertFails(
        updateDoc(doc(authedDb('bob'), PATH('alice')), { share: false, last: deleteField() }),
      );
    });

    it('sharing off = the owner deletes the doc; the partner then reads nothing', async () => {
      await assertFails(deleteDoc(doc(authedDb('bob'), PATH('alice'))));
      await assertFails(deleteDoc(doc(authedDb('dave'), PATH('alice'))));
      await assertSucceeds(deleteDoc(doc(authedDb('alice'), PATH('alice'))));
      const snap = await getDoc(doc(authedDb('bob'), PATH('alice')));
      if (snap.exists()) throw new Error('doc still there');
    });
  });

  // ---- push bookkeeping (CF only, D3/D11) --------------------------------------
  it('arrivalPush: nobody reads or writes it — not the partner, not the owner', async () => {
    const BOOK = (uid) => `couples/c1/arrivalPush/${uid}`;
    await seedDoc(BOOK('alice'), { lastPushAt: { home: TS, p1: TS }, pushDay: '2026-10-20', pushCount: 2 });
    await assertFails(getDoc(doc(authedDb('bob'), BOOK('alice'))));
    await assertFails(getDoc(doc(authedDb('alice'), BOOK('alice'))));
    await assertFails(getDoc(doc(authedDb('dave'), BOOK('alice'))));
    await assertFails(setDoc(doc(authedDb('alice'), BOOK('alice')), { pushCount: 0 }));
    await assertFails(deleteDoc(doc(authedDb('alice'), BOOK('alice'))));
  });

  it('a member who left can no longer write', async () => {
    await seedDoc('couples/c1', validCouple({ memberIds: ['bob'], createdByUserId: 'alice' }));
    await assertFails(write('alice', sharing(event())));
    await assertFails(write('alice', { share: false }));
  });

  // ---- device doc: the new mute key (D16) ------------------------------------
  it('device doc: pushArrival bool passes, a string does not; old docs unaffected', async () => {
    const devices = (uid) => doc(authedDb(uid), `users/${uid}/devices/d1`);
    await assertSucceeds(setDoc(devices('alice'), validDevice({ pushArrival: false })));
    await assertFails(setDoc(devices('alice'), validDevice({ pushArrival: 'off' })));
    await assertSucceeds(setDoc(devices('bob'), validDevice()));
  });
});
