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
  runTransaction,
  serverTimestamp,
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

test('chat authors can append to their own active channel without impersonating another member', async () => {
  const activeCase = 'case_harmon';
  const senderId = 'chat-sender';
  const team = 'chat-team';
  const otherTeam = 'other-chat-team';
  const chat = (db, id, teamId = team) => doc(db, 'teams', teamId, 'chat', id);
  const verified = (uid) => env.authenticatedContext(uid, { email_verified: true }).firestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const id of [team, otherTeam]) {
      await setDoc(doc(db, 'teams', id), { activeCaseId: activeCase });
    }
    for (const uid of [senderId, 'chat-reader', 'unlisted-member']) {
      await setDoc(doc(db, 'memberships', uid), { teamId: team });
    }
    await setDoc(doc(db, 'teams', team, 'members', senderId), { name: 'Sender' });
    await setDoc(doc(db, 'teams', team, 'tasks', 'review'), { title: 'Review' });
    await setDoc(doc(db, 'teams', team, 'cases', activeCase, 'exhibits', 'ex_1'), { title: 'Exhibit' });
  });

  const sender = verified(senderId);
  const reader = verified('chat-reader');
  const unlisted = verified('unlisted-member');
  const outsider = verified('chat-outsider');
  const data = { caseId: activeCase, senderId, text: 'Ready to practice', createdAt: serverTimestamp(), mentions: [] };
  const task = { kind: 'task', itemId: 'review', label: 'Review' };
  const exhibit = { kind: 'exhibit', itemId: 'ex_1', label: 'Exhibit' };

  await assertFails(setDoc(chat(outsider, 'outsider'), {...data, senderId: 'chat-outsider'}));
  await assertFails(setDoc(chat(unlisted, 'unlisted'), {...data, senderId: 'unlisted-member'}));
  await assertFails(setDoc(chat(sender, 'wrong-team', otherTeam), data));
  await assertFails(setDoc(chat(sender, 'spoofed'), {...data, senderId: 'chat-reader'}));
  await assertFails(setDoc(chat(sender, 'inactive'), {...data, caseId: 'case_old'}));
  await assertFails(setDoc(chat(sender, 'client-clock'), {...data, createdAt: Timestamp.now()}));
  await assertFails(setDoc(chat(sender, 'empty'), {...data, text: '  ' }));
  await assertFails(setDoc(chat(sender, 'long'), {...data, text: 'x'.repeat(2001)}));
  await assertFails(setDoc(chat(sender, 'malformed'), {...data, mentions: [42]}));
  await assertFails(setDoc(chat(sender, 'missing-task'), {...data, mentions: [{...task, itemId: 'missing'}]}));
  await assertFails(setDoc(chat(sender, 'duplicates'), {...data, mentions: [task, {...task, label: 'Other label'}]}));
  await assertFails(setDoc(chat(sender, 'private-draft'), {...data, mentions: [{kind: 'draft', itemId: 'opening', label: 'Draft'}]}));

  await assertSucceeds(setDoc(chat(sender, 'text-only'), {...data, text: 'Ready\nto practice'}));
  const payload = {...data, text: '', mentions: [task, exhibit]};
  const reference = chat(sender, 'stable-message-id');
  const send = () => runTransaction(sender, async (transaction) => {
    const saved = await transaction.get(reference);
    if (!saved.exists()) transaction.set(reference, payload);
  });
  await assertSucceeds(send());
  await assertSucceeds(send());
  const history = await assertSucceeds(getDocs(collection(reader, 'teams', team, 'chat')));
  assert.equal(history.size, 2);
  const saved = history.docs.find((message) => message.id === reference.id).data();
  assert.equal(saved.senderId, senderId);
  assert.equal(saved.mentions.length, 2);
  await assertFails(getDoc(chat(outsider, 'stable-message-id')));
  await assertFails(updateDoc(reference, {text: 'Changed'}));
  await assertFails(deleteDoc(reference));
});

test('removing a team closes access to its remaining subcollections', async () => {
  const orphaned = 'deleted-team';
  const uid = 'previous-member';
  const task = (db) => doc(db, 'teams', orphaned, 'tasks', 'old-task');
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'memberships', uid), { teamId: orphaned });
    await setDoc(task(db), { assigneeId: uid, isDone: false });
  });
  const member = env.authenticatedContext(uid, { email_verified: true }).firestore();
  await assertFails(getDoc(task(member)));
  await assertFails(updateDoc(task(member), { isDone: true }));
});

test('captains and coaches assign a role and its exact responsibilities in one write', async () => {
  const team = 'role-team';
  const caseId = 'case_harmon';
  const previousCase = 'old_case';
  const trialDate = '2026-12-14T00:00:00.000';
  const roleId = 'opening';
  const rolePath = (db, id = caseId, role = roleId) =>
    doc(db, 'teams', team, 'cases', id, 'roles', role);
  const taskPath = (db, index, id = caseId, role = roleId) =>
    doc(db, 'teams', team, 'tasks', `role.${id}.${role}.${index}`);
  const captain = 'captain';
  const coach = 'coach';
  const member = 'role-member';
  const recipient = 'role-recipient';
  const responsibilities = ['Draft', 'Rehearse', 'Check time'];
  const signedIn = (uid) => env.authenticatedContext(uid, {email_verified: true}).firestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'teams', team), {activeCaseId: caseId});
    for (const id of [caseId, previousCase]) {
      await setDoc(doc(db, 'teams', team, 'cases', id), {trialDate});
      for (const role of [roleId, 'alternate']) {
        await setDoc(rolePath(db, id, role), {title: 'Attorney', responsibilities});
      }
    }
    for (const [uid, teamRole] of [[captain, 'captain'], [coach, 'coach'], [member, 'member'], [recipient, 'member']]) {
      await setDoc(doc(db, 'memberships', uid), {teamId: team});
      await setDoc(doc(db, 'teams', team, 'members', uid), {teamRole});
    }
  });
  const taskData = (index, assigneeId, id = caseId, role = roleId) => ({
    id: `role.${id}.${role}.${index}`,
    title: `Attorney: ${responsibilities[index]}`,
    assigneeId,
    dueDate: trialDate,
    isDone: false,
    caseId: id,
    roleId: role,
    responsibilityIndex: index,
  });
  const assign = (db, {
    assigneeId = recipient, id = caseId, role = roleId,
    slots = [0, 1, 2], override = {},
  } = {}) => runTransaction(db, async (transaction) => {
    const roleDoc = rolePath(db, id, role);
    await transaction.get(roleDoc);
    transaction.update(roleDoc, {assigneeId});
    for (const index of slots) {
      transaction.set(taskPath(db, index, id, role), {
        ...taskData(index, assigneeId, id, role),
        ...override,
      });
    }
  });
  const captainDb = signedIn(captain);
  const memberDb = signedIn(member);

  await assertSucceeds(getDoc(rolePath(memberDb)));
  await assertFails(updateDoc(doc(memberDb, 'teams', team, 'members', member), {teamRole: 'captain'}));
  await assertFails(assign(memberDb));
  await assertFails(assign(captainDb, {id: previousCase}));
  await assertFails(assign(captainDb, {assigneeId: 'not-on-roster'}));
  await assertFails(updateDoc(rolePath(captainDb), {assigneeId: recipient}));
  await assertFails(assign(captainDb, {slots: [0, 1]}));
  await assertFails(assign(captainDb, {override: {title: 'Untrusted'}}));
  await assertFails(assign(captainDb, {override: {dueDate: '2026-11-21T00:00:00.000'}}));
  await assertFails(setDoc(taskPath(captainDb, 0), taskData(0, recipient)));

  const outcomes = await Promise.allSettled([
    assign(captainDb),
    assign(signedIn(coach), {assigneeId: member}),
  ]);
  assert.equal(outcomes.filter((result) => result.status === 'fulfilled').length, 1);
  const assigned = (await assertSucceeds(getDoc(rolePath(memberDb)))).data().assigneeId;
  for (const index of [0, 1, 2]) {
    const task = await assertSucceeds(getDoc(taskPath(memberDb, index)));
    assert.deepEqual(task.data(), taskData(index, assigned));
  }
  await assertFails(assign(captainDb, {assigneeId: 'not-on-roster'}));
  await assertFails(deleteDoc(rolePath(captainDb)));
  await assertSucceeds(assign(signedIn(coach), {role: 'alternate'}));
});

test('practice follow-ups must link to a session shared by both rostered teammates', async () => {
  const team = 'practice-team';
  const sessionId = 'practice_1';
  const author = 'practice-author';
  const participant = 'practice-participant';
  const nonparticipant = 'practice-nonparticipant';
  const signedIn = (uid) => env.authenticatedContext(uid, {email_verified: true}).firestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'teams', team), {activeCaseId: 'case_harmon'});
    await setDoc(doc(db, 'teams', team, 'sessions', sessionId), {participantIds: [author, participant, 'not-rostered']});
    for (const uid of [author, participant, nonparticipant]) {
      await setDoc(doc(db, 'memberships', uid), {teamId: team});
      await setDoc(doc(db, 'teams', team, 'members', uid), {name: uid});
    }
  });
  const id = 'follow_up_' + 'a'.repeat(32);
  const task = (db) => doc(db, 'teams', team, 'tasks', id);
  const data = {
    id, sessionId, assigneeId: participant, title: 'Review exhibit',
    dueDate: '2026-11-22T00:00:00.000', isDone: false,
    workRoute: '/me/schedule/' + sessionId,
  };
  const authorDb = signedIn(author);
  const participantDb = signedIn(participant);
  await assertFails(setDoc(task(signedIn(nonparticipant)), data));
  await assertFails(setDoc(task(authorDb), {...data, assigneeId: nonparticipant}));
  await assertFails(setDoc(task(authorDb), {...data, assigneeId: 'not-rostered'}));
  await assertFails(setDoc(task(authorDb), {...data, workRoute: '/team'}));
  await assertFails(setDoc(task(authorDb), {...data, title: ' '}));
  await assertFails(setDoc(task(authorDb), {...data, isDone: true}));
  await assertSucceeds(setDoc(task(authorDb), data));
  assert.equal((await assertSucceeds(getDoc(task(participantDb)))).data().title, data.title);
  await assertSucceeds(updateDoc(task(participantDb), {isDone: true}));
  await assertFails(updateDoc(task(authorDb), {isDone: false}));
});
