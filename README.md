# Healthie Rails pre-work

A Rails 8.1 app on Postgres. It's a data layer only: models, migrations, seeds and queries. There are no controllers or views.

## Running it locally

_TODO_

## Data model

_TODO_

## Design decisions

- I use "patient" instead of the guide's "client". Same thing.
- Names are split into first and last name. That makes sorting and formal display ("Dr. Lee") easier.
- Rules are enforced in both the model and the database. Validations give readable errors. `NOT NULL` columns, foreign keys and unique indexes still hold when validations are skipped, for example by raw SQL, bulk inserts, or two requests at once.
- Emails are trimmed and lowercased before saving, so `Maria@x.com` and `maria@x.com` are the same address. An email is unique within each table, so one person can have both a provider and a patient record.
- Primary keys are UUIDv7. Sequential IDs are guessable and show how many records exist, which matters for health data. v7 IDs are time-ordered, so inserts stay fast as tables grow. The downside is that an ID shows when its record was created. Postgres 14 can't generate v7, so Ruby does it in `ApplicationRecord`. UUIDs don't replace authorization.
- The plan belongs to the subscription, so a patient can be premium with one provider and basic with another. Plans are rows in a `plans` table shared by all providers, so adding a tier doesn't need a migration.
- Subscription status is one of `pending`, `active`, `paused` or `cancelled`, enforced by a check constraint. It's a column rather than a table because the code depends on these exact values.
- A provider can see a patient's journal entries only while their subscription is `active`.
- Each patient–provider pair has at most one subscription. Re-subscribing reactivates the existing row.
- A patient, provider or plan that still has subscriptions or journal entries can't be deleted. Records get cancelled, not deleted.

## Open questions

- Should Provider and Patient share code? Their validations are the same today, so a shared concern would work. I kept them separate because they'll likely diverge. For example, providers may need licensing data per state.
- Can a provider also be a patient? Right now that would be two unrelated records with the same email. If it's common, a shared `people` table with provider and patient roles would fit better.
- Should subscription changes be audited? `updated_at` only shows the last change, not who made it. Patients, providers and staff could all change a subscription. A separate `subscription_events` table would keep the full history.
- Should entries have a date the patient picks? Entries sort by when they were saved. That's simple and can't be backdated, but a patient can't log something about last week. An `occurred_at` column would allow it.
- Should patients be able to edit entries? Sort order wouldn't change, but if a provider acted on the original text, the edit history may need to be kept.
- Should a provider keep access to entries written before a cancellation? Providers often need to keep records they relied on. That would need a `cancelled_at` timestamp. For now, access ends completely.

## Future work

- Provider credentials and licensing, stored per state.
- Queries for other statuses. All four queries only use active subscriptions, on the assumption that providers mostly care about current patients. Supporting paused or pending patients would mean passing a status in, or dropping the filter.
- Feed pagination. The feed returns every entry today. The next step is a cursor: the client sends back the last entry's `created_at` and `id`, and the next page is `WHERE (created_at, id) < (cursor) ORDER BY created_at DESC, id DESC LIMIT n`. The `(patient_id, created_at, id)` index makes that a quick range read. I'd use a cursor over `OFFSET` because offset still reads every skipped row, and new entries shift the pages.

## Known gaps

_TODO_
