import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const active = 'active-test-code-000000001';
const expired = 'expired-test-code-00000001';
const inactive = 'inactive-test-code-0000001';
const missingTeam = 'missing-team-code-00000001';
const teamId = 'trial-team';
let env;

before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-gavel' });
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const future = Timestamp.fromMillis(Date.now() + 3_600_000);
    const past = Timestamp.fromMillis(Date.now() - 3_600_000);
    await setDoc(doc(db, 'teams', teamId), { name: 'Trial team' });
    for (const [code, data] of [
      [active, { teamId, active: true, expiresAt: future }],
      [expired, { teamId, active: true, expiresAt: past }],
      [inactive, { teamId, active: false, expiresAt: future }],
      [missingTeam, { teamId: 'missing', active: true, expiresAt: future }],
    ]) {
      await setDoc(doc(db, 'teamInvites', code), data);
    }
  });
});

after(async () => {
  await env?.cleanup();
});

test('only verified users can redeem a live invite for themselves', async () => {
  const guest = env.unauthenticatedContext().firestore();
  const unverified = env.authenticatedContext('unverified', {
    email_verified: false,
  }).firestore();
  const member = env.authenticatedContext('member', {
    email_verified: true,
  }).firestore();
  const invite = (db, code = active) => doc(db, 'teamInvites', code);
  const membership = (db, uid = 'member') => doc(db, 'memberships', uid);
  const data = { teamId, inviteCode: active };

  await assertFails(getDoc(invite(guest)));
  await assertFails(getDoc(invite(unverified)));
  await assertFails(setDoc(membership(unverified, 'unverified'), data));
  await assertFails(getDocs(collection(member, 'teamInvites')));
  await assertFails(setDoc(invite(member, 'fabricated-test-code-00001'), data));
  for (const code of [expired, inactive, missingTeam, 'unknown-test-code-0000001']) {
    await assertFails(getDoc(invite(member, code)));
    await assertFails(setDoc(membership(member), { teamId, inviteCode: code }));
  }
  await assertSucceeds(getDoc(invite(member)));
  await assertFails(setDoc(membership(member, 'other'), data));
  await assertFails(setDoc(membership(member), { ...data, teamId: 'other' }));
  await assertFails(setDoc(membership(member), { ...data, role: 'coach' }));
  await assertSucceeds(setDoc(membership(member), data));
  assert.equal((await assertSucceeds(getDoc(membership(member)))).data().teamId, teamId);
  await assertFails(getDoc(membership(member, 'other')));
  await assertFails(getDocs(collection(member, 'memberships')));
  await assertFails(updateDoc(membership(member), { teamId: 'other' }));
  await assertFails(deleteDoc(membership(member)));
  await assertSucceeds(getDoc(doc(member, 'teams', teamId)));
});

test('workspace reads are limited to members of that team', async () => {
  const other = 'other-team';
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const team of [teamId, other]) {
      await setDoc(doc(db, 'teams', team), { activeCaseId: 'case_harmon' });
      await setDoc(doc(db, 'teams', team, 'tasks', 'task_1'), { title: 'Review' });
      await setDoc(doc(db, 'teams', team, 'cases', 'case_harmon', 'exhibits', 'ex_1'), { title: 'Exhibit' });
    }
    await setDoc(doc(db, 'memberships', 'reader'), { teamId });
  });
  const reader = env.authenticatedContext('reader', { email_verified: true }).firestore();
  const outsider = env.authenticatedContext('outsider', { email_verified: true }).firestore();
  const tasks = (db, team) => collection(db, 'teams', team, 'tasks');
  const exhibit = (db, team) => doc(db, 'teams', team, 'cases', 'case_harmon', 'exhibits', 'ex_1');

  await assertSucceeds(getDocs(tasks(reader, teamId)));
  await assertSucceeds(getDoc(exhibit(reader, teamId)));
  await assertFails(getDocs(tasks(reader, other)));
  await assertFails(getDoc(exhibit(reader, other)));
  await assertFails(getDocs(tasks(outsider, teamId)));
  await assertFails(getDocs(collection(reader, 'teams')));
  await assertFails(setDoc(doc(tasks(reader, teamId), 'new'), { title: 'Blocked' }));
  await assertFails(updateDoc(exhibit(reader, teamId), { title: 'Blocked' }));
});

test('only an assignee can change completion and teammates see the update', async () => {
  const assigneeId = 'task-assignee';
  const otherTeam = 'other-task-team';
  const path = (db, team = teamId, id = 'owned') =>
    doc(db, 'teams', team, 'tasks', id);
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'memberships', assigneeId), { teamId });
    await setDoc(doc(db, 'memberships', 'task-teammate'), { teamId });
    for (const team of [teamId, otherTeam]) {
      await setDoc(path(db, team), { assigneeId, isDone: false, title: 'Review' });
    }
  });
  const assignee = env.authenticatedContext(assigneeId, { email_verified: true }).firestore();
  const teammate = env.authenticatedContext('task-teammate', { email_verified: true }).firestore();
  const unverified = env.authenticatedContext(assigneeId, { email_verified: false }).firestore();

  await assertFails(updateDoc(path(teammate), { isDone: true }));
  await assertFails(updateDoc(path(unverified), { isDone: true }));
  await assertFails(updateDoc(path(assignee, otherTeam), { isDone: true }));
  await assertFails(updateDoc(path(assignee), { isDone: true, title: 'Edited' }));
  await assertFails(updateDoc(path(assignee), { assigneeId: 'task-teammate' }));
  await assertFails(updateDoc(path(assignee), { isDone: 'true' }));
  await assertFails(deleteDoc(path(assignee)));
  await assertFails(setDoc(path(assignee, teamId, 'new'), { assigneeId, isDone: false }));

  for (const isDone of [true, false]) {
    await assertSucceeds(updateDoc(path(assignee), { isDone }));
    const task = await assertSucceeds(getDoc(path(teammate)));
    assert.equal(task.data().isDone, isDone);
    assert.equal(task.data().title, 'Review');
  }
});
