# Healthie Rails pre-work

A Rails 8.1 app on Postgres, used as a data layer only: models, migrations, seeds and queries, with no controllers or views.

## Running it locally

_TODO: Ruby/Postgres prerequisites, setup, seeding, running the queries._

## Data model

_TODO: tables and associations diagram._

## Design decisions

- **"Patient", not "client".** The guide says "client". This app uses `Patient` / `patient_id` throughout. They refer to the same thing.
- **First and last name**, not a single `name` field, for sorting, searching and formal display ("Dr. Lee").
- **Rules enforced in both the model and the database.** Model validations give readable errors. `NOT NULL` columns and a unique email index guarantee the data even when validations are bypassed, for example by raw SQL, bulk inserts, or two requests racing past the uniqueness check.
- **Emails are normalized** (trimmed and lowercased) before saving, so `Maria@x.com` and `maria@x.com` count as the same address. Emails are unique per table: the same address may belong to one provider and one patient.
- **UUIDv7 primary keys.** Sequential IDs are guessable and reveal record counts, which matters for health data. v7 is time-ordered, so inserts stay index-friendly at scale, unlike random v4. The tradeoff is that the ID reveals when a record was created. Postgres 14 has no native v7 generator, so Ruby assigns it (`ApplicationRecord`). The column's `gen_random_uuid()` default is a fallback for inserts that bypass Rails. UUIDs prevent enumeration but are not access control: authorization is still required.

- **The plan lives on the subscription**, so a patient can be premium with one provider and basic with another. Plans are rows in a `plans` table (`basic`, `premium`) shared by all providers: adding a tier is data, not a migration.
- **Subscription status is a fixed list**: `pending`, `active`, `paused`, `cancelled`, stored as a column with a database check constraint. Unlike plans, statuses drive code (only `active` grants access), so a table would add a join without adding flexibility.
- **Only active subscriptions grant access.** A provider sees a patient's journal entries only while their subscription is `active`. Cancelling removes access to all entries, including older ones (see open questions).
- **One subscription per patient–provider pair**, enforced by a unique index and a validation. Re-subscribing reactivates the existing row.
- **Deleting a patient, provider or plan that still has subscriptions is blocked** (`dependent: :restrict_with_error`, backed by foreign keys). Clinical history shouldn't vanish silently: subscriptions are cancelled, not deleted.

## Open product questions

- **Should Provider and Patient share code?** Today both models have identical name and email rules, which would fit a shared concern (`app/models/concerns`). I've kept them separate on purpose, because product requirements are likely to pull them apart. Providers, for example, may need state-by-state licensing data that patients never have. Extracting a concern is cheap once the overlap proves stable.
- **Can a provider also be a patient?** A dietitian could reasonably want care from another provider. Today the tables are separate, so one person would have two unrelated records, linked only by matching emails. If this turns out to be common, a shared identity table (`people` or `users`) with provider and patient roles pointing to it would model it directly. How likely this is depends on the product, so it's left open.

- **Should subscription changes have an audit history?** `created_at` records when a subscription was created, and `updated_at` only records the *most recent* change. That makes it impossible to answer "who moved this patient to premium, and when?" Changes can come from the patient, the provider, or staff such as admins or customer success. A separate append-only `subscription_events` table (old value, new value, who changed it, when) would answer that, and supports HIPAA-style audit requirements.
- **Should providers keep access to entries written before a cancellation?** Providers often need to retain the records they relied on. This would need a `cancelled_at` timestamp and a date comparison in the feed query. For simplicity, access currently ends completely.

## Future work

- A table for provider credentials and licensing, per state the provider practices in.

## Incomplete / known gaps

_TODO._
