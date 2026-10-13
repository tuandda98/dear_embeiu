// Sleep rules (feature sleep, 2026-10-10).
//   couples/{coupleId}/sleep/{uid}               — profile: share flag + colour
//   couples/{coupleId}/sleep/{uid}/nights/{date} — one night, id == wake date
// The partner reads the nights ONLY while the owner's `share` flag is on
// (rules-enforced, not just hidden in the UI). While shared, only nights that
// ended within the last 8 days can be edited/deleted (R3: 7 nights + 1 day of
// timezone slack). Create has no age limit so turning sharing back on can
// re-upload the history; turning sharing off unlocks deleting every night.

const assert = require('node:assert');
const {
  doc,
  setDoc,
  getDoc,
  getDocs,
  updateDoc,
  deleteDoc,
  collection,
  Timestamp,
} = require('firebase/firestore');
const {
  assertSucceeds,
  assertFails,
  authedDb,
  seedDoc,
  seedActiveCouple,
  validCouple,
  TS,
} = require('./helpers');

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

const PROFILE = (uid) => `couples/c1/sleep/${uid}`;
const NIGHTS = (uid) => `couples/c1/sleep/${uid}/nights`;
const nightPath = (uid, n) => `${NIGHTS(uid)}/${n.date}`;

// A valid night that ended `daysAgo` days ago (negative = in the future),
// 7h45 in bed. Doc id must equal `date`, so always write it via nightPath().
function night(daysAgo, overrides = {}) {
  const wake = Date.now() - daysAgo * DAY;
  return {
    date: new Date(wake).toISOString().slice(0, 10),
    bedAt: Timestamp.fromMillis(wake - 7.75 * HOUR),
    wakeAt: Timestamp.fromMillis(wake),
    wakeUps: [42, 180],
    source: 'auto',
    updatedAt: TS,
    ...overrides,
  };
}

describe('firestore: sleep', () => {
  beforeEach(async () => {
    // active couple c1 = {alice, bob}; dave is an outsider.
    await seedActiveCouple('c1', 'alice', 'bob');
  });

  const sharing = (uid, share) =>
    seedDoc(PROFILE(uid), { share, color: 'rose', updatedAt: TS });

  // ---- profile ---------------------------------------------------------------
  describe('profile', () => {
    it('lets a member write their own profile', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), PROFILE('alice')), { share: true, color: 'teal', updatedAt: TS }),
      );
    });

    it('accepts a partial merge write (every field optional)', async () => {
      await assertSucceeds(
        setDoc(doc(authedDb('alice'), PROFILE('alice')), { share: false }, { merge: true }),
      );
    });

    it('rejects a colour outside the palette (ids only, never a hex)', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), PROFILE('alice')), { share: true, color: '#FF4D6D' }),
      );
    });

    it('rejects a non-bool share flag', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), PROFILE('alice')), { share: 'yes' }),
      );
    });

    it('rejects an unexpected field', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), PROFILE('alice')), { share: true, color: 'rose', secret: 'x' }),
      );
    });

    it('forbids writing the partner profile', async () => {
      await assertFails(
        setDoc(doc(authedDb('alice'), PROFILE('bob')), { share: true, color: 'rose' }),
      );
    });

    it('lets the partner read the profile (flag + colour)', async () => {
      await sharing('alice', false);
      await assertSucceeds(getDoc(doc(authedDb('bob'), PROFILE('alice'))));
    });

    it('forbids an outsider reading the profile', async () => {
      await sharing('alice', true);
      await assertFails(getDoc(doc(authedDb('dave'), PROFILE('alice'))));
    });

    it('forbids deleting a profile', async () => {
      await sharing('alice', true);
      await assertFails(deleteDoc(doc(authedDb('alice'), PROFILE('alice'))));
    });
  });

  // ---- profile: switching sharing on (audit 2026-10-12) ----------------------
  // An "on" queued offline must not land after the partner left and upload the
  // history to a couple waiting for someone new.
  describe('profile: switching sharing on', () => {
    const alone = () => seedDoc('couples/c1', validCouple({ memberIds: ['alice'] }));
    const write = (data) =>
      setDoc(doc(authedDb('alice'), PROFILE('alice')), data, { merge: true });

    it('forbids switching sharing on in a couple of one', async () => {
      await alone();
      await assertFails(write({ share: true, color: 'rose', updatedAt: TS }));
    });

    it('forbids an "on" landing after the partner left (flag already off)', async () => {
      await sharing('alice', false);
      await alone();
      await assertFails(write({ share: true }));
    });

    it('lets a member switch sharing on when both are in the couple', async () => {
      await sharing('alice', false);
      await assertSucceeds(write({ share: true }));
    });

    it('still lets a member already sharing change colour in a couple of one', async () => {
      await sharing('alice', true);
      await alone();
      await assertSucceeds(write({ color: 'teal', updatedAt: TS }));
    });

    // Released apps save the colour (no share) when sleep is set up while
    // still waiting for a partner.
    it('lets a member waiting for a partner save a colour or switch sharing off', async () => {
      await alone();
      await assertSucceeds(write({ color: 'rose', updatedAt: TS }));
      await assertSucceeds(write({ share: false }));
    });
  });

  // ---- nights: create --------------------------------------------------------
  describe('nights: create', () => {
    it('lets the owner upload a night while sharing', async () => {
      await sharing('alice', true);
      const n = night(1);
      await assertSucceeds(setDoc(doc(authedDb('alice'), nightPath('alice', n)), n));
    });

    it('accepts a night without the optional wakeUps / updatedAt', async () => {
      await sharing('alice', true);
      const { wakeUps, updatedAt, ...bare } = night(1);
      await assertSucceeds(setDoc(doc(authedDb('alice'), nightPath('alice', bare)), bare));
    });

    it('forbids uploading a night while sharing is off', async () => {
      await sharing('alice', false);
      const n = night(1);
      await assertFails(setDoc(doc(authedDb('alice'), nightPath('alice', n)), n));
    });

    it('forbids uploading a night before any profile exists', async () => {
      const n = night(1);
      await assertFails(setDoc(doc(authedDb('alice'), nightPath('alice', n)), n));
    });

    // Deliberate: re-enabling sharing re-uploads the whole local history, so
    // create has no 8-day limit (only update/delete do).
    it('lets the owner re-upload a night from 20 days ago while sharing', async () => {
      await sharing('alice', true);
      const n = night(20);
      await assertSucceeds(setDoc(doc(authedDb('alice'), nightPath('alice', n)), n));
    });
  });

  // ---- nights: shape ---------------------------------------------------------
  describe('nights: invalid shape', () => {
    const invalid = {
      'wakeAt == bedAt': (n) => ({ ...n, bedAt: n.wakeAt }),
      'a sleep longer than 16h': (n) => ({ ...n, bedAt: Timestamp.fromMillis(n.wakeAt.toMillis() - 17 * HOUR) }),
      'an unknown source': (n) => ({ ...n, source: 'watch' }),
      'no source': ({ source, ...rest }) => rest,
      'an extra field (no original times — R2)': (n) => ({ ...n, originalBedAt: n.bedAt }),
      '61 wake-ups': (n) => ({ ...n, wakeUps: Array(61).fill(5) }),
      'a wakeAt 2 days in the future': () => night(-2),
      'a numeric bedAt': (n) => ({ ...n, bedAt: n.bedAt.toMillis() }),
      'a numeric wakeAt': (n) => ({ ...n, wakeAt: n.wakeAt.toMillis() }),
      'wakeUps as a string': (n) => ({ ...n, wakeUps: '42,180' }),
      'wakeUps as a map': (n) => ({ ...n, wakeUps: { first: 42 } }),
      'a string updatedAt': (n) => ({ ...n, updatedAt: '2026-01-01' }),
      // Doc id == date, so these are junk ids of the old "10 chars" shape.
      'a date id that is not YYYY-MM-DD': (n) => ({ ...n, date: '2026-1-011' }),
      'a 10-letter date id': (n) => ({ ...n, date: 'abcdefghij' }),
      'tz 900 (beyond ±14h)': (n) => ({ ...n, tz: 900 }),
      'tz as a string': (n) => ({ ...n, tz: '420' }),
      'a fractional tz': (n) => ({ ...n, tz: 420.5 }),
    };
    for (const [name, mutate] of Object.entries(invalid)) {
      it(`rejects a night with ${name}`, async () => {
        await sharing('alice', true);
        const n = mutate(night(1));
        await assertFails(setDoc(doc(authedDb('alice'), nightPath('alice', n)), n));
      });
    }

    it('accepts exactly 60 wake-ups', async () => {
      await sharing('alice', true);
      const n = night(1, { wakeUps: Array(60).fill(5) });
      await assertSucceeds(setDoc(doc(authedDb('alice'), nightPath('alice', n)), n));
    });

    // 1.9.1+ (audit D2): minutes east of UTC when the night was recorded.
    it('accepts the optional tz (whole minutes within ±14h)', async () => {
      await sharing('alice', true);
      for (const [daysAgo, tz] of [[1, 420], [2, -300]]) {
        const n = night(daysAgo, { tz });
        await assertSucceeds(setDoc(doc(authedDb('alice'), nightPath('alice', n)), n));
      }
    });

    it('rejects a date that does not match the doc id', async () => {
      await sharing('alice', true);
      await assertFails(
        setDoc(doc(authedDb('alice'), `${NIGHTS('alice')}/2020-01-01`), night(1)),
      );
    });
  });

  // ---- nights: read ----------------------------------------------------------
  describe('nights: read', () => {
    const seedNight = async () => {
      const n = night(1);
      await seedDoc(nightPath('alice', n), n);
      return n;
    };

    it('lets the partner get and list the nights while sharing is on', async () => {
      await sharing('alice', true);
      const n = await seedNight();
      const db = authedDb('bob');
      await assertSucceeds(getDoc(doc(db, nightPath('alice', n))));
      const snap = await assertSucceeds(getDocs(collection(db, NIGHTS('alice'))));
      assert.strictEqual(snap.size, 1);
    });

    it('hides the nights from the partner while sharing is off (get + list)', async () => {
      await sharing('alice', false);
      const n = await seedNight();
      const db = authedDb('bob');
      await assertFails(getDoc(doc(db, nightPath('alice', n))));
      await assertFails(getDocs(collection(db, NIGHTS('alice'))));
    });

    it('always lets the owner read their own nights, even with sharing off', async () => {
      await sharing('alice', false);
      const n = await seedNight();
      const db = authedDb('alice');
      await assertSucceeds(getDoc(doc(db, nightPath('alice', n))));
      await assertSucceeds(getDocs(collection(db, NIGHTS('alice'))));
    });

    it('forbids an outsider reading the nights', async () => {
      await sharing('alice', true);
      const n = await seedNight();
      const db = authedDb('dave');
      await assertFails(getDoc(doc(db, nightPath('alice', n))));
      await assertFails(getDocs(collection(db, NIGHTS('alice'))));
    });

    it('hides the nights from the partner while the owner has no profile', async () => {
      const n = await seedNight();
      const db = authedDb('bob');
      await assertFails(getDoc(doc(db, nightPath('alice', n))));
      await assertFails(getDocs(collection(db, NIGHTS('alice'))));
    });
  });

  // ---- nights: update (R3) ---------------------------------------------------
  describe('nights: update', () => {
    it('lets the owner edit a night from 3 days ago', async () => {
      await sharing('alice', true);
      const n = night(3);
      await seedDoc(nightPath('alice', n), n);
      await assertSucceeds(
        updateDoc(doc(authedDb('alice'), nightPath('alice', n)), {
          bedAt: Timestamp.fromMillis(n.wakeAt.toMillis() - 6 * HOUR),
          source: 'edited',
        }),
      );
    });

    it('forbids editing even a recent night once sharing is off', async () => {
      await sharing('alice', false);
      const n = night(3);
      await seedDoc(nightPath('alice', n), n);
      await assertFails(
        updateDoc(doc(authedDb('alice'), nightPath('alice', n)), { source: 'edited' }),
      );
    });

    it('freezes a night from 20 days ago while sharing', async () => {
      await sharing('alice', true);
      const n = night(20);
      await seedDoc(nightPath('alice', n), n);
      await assertFails(
        updateDoc(doc(authedDb('alice'), nightPath('alice', n)), { source: 'edited' }),
      );
    });

    it('forbids moving a recent night back 20 days', async () => {
      await sharing('alice', true);
      const n = night(3);
      await seedDoc(nightPath('alice', n), n);
      const old = night(20);
      await assertFails(
        updateDoc(doc(authedDb('alice'), nightPath('alice', n)), {
          bedAt: old.bedAt,
          wakeAt: old.wakeAt,
          source: 'edited',
        }),
      );
    });
  });

  // ---- nights: delete --------------------------------------------------------
  describe('nights: delete', () => {
    it('lets the owner delete a night from 3 days ago while sharing', async () => {
      await sharing('alice', true);
      const n = night(3);
      await seedDoc(nightPath('alice', n), n);
      await assertSucceeds(deleteDoc(doc(authedDb('alice'), nightPath('alice', n))));
    });

    it('forbids deleting a night from 20 days ago while sharing', async () => {
      await sharing('alice', true);
      const n = night(20);
      await seedDoc(nightPath('alice', n), n);
      await assertFails(deleteDoc(doc(authedDb('alice'), nightPath('alice', n))));
    });

    it('lets the owner wipe a 20-day-old night once sharing is off', async () => {
      await sharing('alice', false);
      const n = night(20);
      await seedDoc(nightPath('alice', n), n);
      await assertSucceeds(deleteDoc(doc(authedDb('alice'), nightPath('alice', n))));
    });
  });

  // ---- nights: the partner never writes -------------------------------------
  it('forbids the partner creating, editing or deleting the owner nights', async () => {
    await sharing('alice', true);
    const n = night(1);
    const ref = doc(authedDb('bob'), nightPath('alice', n));
    await assertFails(setDoc(ref, n));
    await seedDoc(nightPath('alice', n), n);
    await assertFails(setDoc(ref, { ...n, source: 'edited' }));
    await assertFails(deleteDoc(ref));
  });

  // ---- owner left the couple ------------------------------------------------
  describe('owner no longer in the couple', () => {
    it('hides a former member\'s shared nights from whoever is in the couple now', async () => {
      await sharing('alice', true);
      const n = night(1);
      await seedDoc(nightPath('alice', n), n);
      // alice leaves; carol joins in her place (her flag is still on).
      await seedDoc('couples/c1', require('./helpers').validCouple({
        memberIds: ['bob', 'carol'],
        createdByUserId: 'bob',
      }));
      await assertFails(getDoc(doc(authedDb('carol'), nightPath('alice', n))));
      await assertFails(getDocs(collection(authedDb('bob'), NIGHTS('alice'))));
    });

    // Cleaning up after a member who left is the Cloud Functions' job.
    it('locks a former member out of their own nights and profile', async () => {
      await sharing('alice', true);
      const n = night(1);
      await seedDoc(nightPath('alice', n), n);
      await seedDoc('couples/c1', validCouple({ memberIds: ['bob'] }));
      const db = authedDb('alice');
      await assertFails(getDoc(doc(db, PROFILE('alice'))));
      await assertFails(setDoc(doc(db, PROFILE('alice')), { share: false }, { merge: true }));
      await assertFails(getDoc(doc(db, nightPath('alice', n))));
      await assertFails(getDocs(collection(db, NIGHTS('alice'))));
      await assertFails(setDoc(doc(db, nightPath('alice', n)), { ...n, source: 'edited' }));
      const fresh = night(2);
      await assertFails(setDoc(doc(db, nightPath('alice', fresh)), fresh));
      await assertFails(deleteDoc(doc(db, nightPath('alice', n))));
    });
  });
});
