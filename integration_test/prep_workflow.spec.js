import { expect, test } from '@playwright/test';

async function enableAccessibility(page) {
  const enable = page.getByRole('button', { name: 'Enable accessibility' });
  // Flutter places the screen-reader opt-in outside the viewport.
  await enable.dispatchEvent('click');
  await expect(enable).toHaveCount(0);
}

test('preparation work survives a Chrome reload', async ({ page }) => {
  const button = (name) => page.getByRole('button', {
    name,
    exact: typeof name === 'string',
  });
  const type = async (name, value) => {
    const field = page.getByRole('textbox', { name });
    await field.click();
    await expect(field).toBeFocused();
    // The semantic input receives browser focus before Flutter attaches its editor.
    await expect(field).toHaveCSS('font-family', /Inter/);
    await page.keyboard.insertText(value);
    await expect(field).toHaveValue(value);
  };
  const question = 'What did you see when you arrived?';
  const message = 'Officer Reyes is ready for review.';
  const followUp = 'Rehearse the Reyes direct examination';
  const scriptLink = button(/^Draft · Officer Dana Reyes · Direct examination$/);
  const followUpTask = page.getByRole('checkbox', { name: followUp });

  await page.clock.setFixedTime(new Date('2026-10-26T19:00:00Z'));
  await page.goto('/');
  await enableAccessibility(page);

  await test.step('Open the assignment and draft a question', async () => {
    await button('Enter the war room').click();
    await button(/Draft direct exam of Officer Reyes/).click();
    await button('Add question').click();
    await type('Question', question);
    await button('Save question').click();
  });

  await test.step('Attach a Research citation and mark the script ready', async () => {
    await button('Research').click();
    await button('Build the case timeline').click();
    await button('1 · 911 call transcript').first().click();
    await button('Save to Library').click();
    await expect(button('Saved to Library')).toBeVisible();
    await button('Attach to question 1').click();
    await button('Home').click();
    await button(/Draft direct exam of Officer Reyes/).click();
    await expect(button(/Ex\. 4/)).toBeVisible();
    await button(/Drafting/).click();
    await page.getByRole('menuitem', { name: 'Ready for review', exact: true }).click();
    await expect(button(/Ready for review/)).toBeVisible();
  });

  await test.step('Share a link to the script in Team Chat', async () => {
    await button('Team').click();
    await button('Open team chat').click();
    await button('Link item').click();
    await button('Drafts').click();
    await page.getByRole('checkbox', {
      name: /Officer Dana Reyes.*Direct/,
    }).click();
    await button('Apply links').click();
    await type('Message your team', message);
    await button('Send').click();
    await scriptLink.click();
    await expect(page.getByRole('group', { name: question })).toBeVisible();
  });

  await test.step('Create a practice agenda and follow-up', async () => {
    await button('Profile').click();
    await button(/Practice Schedule/i).click();
    await button('Open agenda').first().click();
    await button(/Add script or argument/).click();
    await page.getByRole('menuitem', { name: 'Opening statement', exact: true }).click();
    await button('Assign a follow-up task').click();
    await type('Task title', followUp);
    await button('Assign task').click();
    await button('Profile').click();
    await followUpTask.click();
    await expect(followUpTask).toBeChecked();
  });

  await test.step('Reload and verify the saved workflow', async () => {
    await page.reload();
    await enableAccessibility(page);
    await expect(button('Enter the war room')).toHaveCount(0);
    await button('Profile').click();
    await expect(followUpTask).toBeChecked();

    await button(/Practice Schedule/i).click();
    await button('Open agenda').first().click();
    await expect(button('Open draft')).toBeVisible();

    await button('Team').click();
    await button('Open team chat').click();
    await scriptLink.click();
    await expect(page.getByRole('group', { name: question })).toBeVisible();
    await expect(button(/Ready for review/)).toBeVisible();
    await button('Ex. 4').click();
    await expect(button('Saved to Library')).toBeVisible();
  });
});
