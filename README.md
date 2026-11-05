# Healthie Rails pre-work

A Rails 8.1 app on Postgres. It's a data layer only: models, migrations, seeds and queries. There are no controllers or views.

## Running it locally

You need Ruby 3.4.12 (see `.ruby-version`) and Postgres 13 or newer running locally.

```
bundle install
bin/rails db:setup                      # create the databases, load the schema, seed sample data
bin/rails runner script/queries.rb      # run the four required queries against the seed data
```

By default Rails connects to Postgres as your OS user. To use a different user or host, set `DATABASE_URL`, for example `DATABASE_URL=postgres://user:pass@localhost/healthie_rails_app_development`.

To explore the data yourself, open `bin/rails console`:

```ruby
lee = Provider.find_by(email: "dr.lee@example.com")
lee.active_patients      # 1. patients for a provider
lee.journal_feed         # 4. entries across a provider's patients, newest first

maria = Patient.find_by(email: "maria@example.com")
maria.active_providers                  # 2. providers for a patient
maria.journal_entries.newest_first      # 3. a patient's entries, newest first
```

Each query is a single SQL query. Append `.to_sql` to see it.

### Sample data

|       | Dr. Lee | Dr. Patel |
| ----- | ------- | --------- |
| Maria | premium | basic     |
| Sam   | basic   | none      |
| Jo    | none    | none      |

All subscriptions are active. Maria has 3 journal entries, Sam 2 and Jo 1. Jo's entry never appears in a provider's feed.

## Data model

```mermaid
erDiagram
    PROVIDER ||--o{ SUBSCRIPTION : has
    PATIENT  ||--o{ SUBSCRIPTION : has
    PLAN     ||--o{ SUBSCRIPTION : "is chosen by"
    PATIENT  ||--o{ JOURNAL_ENTRY : writes

    PROVIDER { uuid id string first_name string last_name string email }
    PATIENT  { uuid id string first_name string last_name string email }
    PLAN     { uuid id string name }
    SUBSCRIPTION { uuid id uuid patient_id uuid provider_id uuid plan_id string status }
    JOURNAL_ENTRY { uuid id uuid patient_id text body }
```

Every table also has `created_at` and `updated_at`.

A subscription is the link between one patient and one provider. Patients and providers are many-to-many through it. Journal entries belong to the patient only. A provider reaches them through an active subscription.

Indexes:

| Index                                                      | Used for                                                                   |
| ---------------------------------------------------------- | -------------------------------------------------------------------------- |
| `providers.email`, `patients.email`, `plans.name` (unique) | Lookups and the uniqueness rules                                           |
| `subscriptions (patient_id, provider_id)` (unique)         | One subscription per pair, and a patient's providers                       |
| `subscriptions.provider_id`                                | A provider's patients, and the first step of the feed                      |
| `subscriptions.plan_id`                                    | The foreign key check when a plan is deleted                               |
| `journal_entries (patient_id, created_at, id)`             | A patient's entries newest first, the feed, and a future pagination cursor |

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

- Billing. A next billing date on the subscription would be simple to add. Payment methods should live with a payment processor such as Stripe, with only a reference stored here.

## Known gaps

- No automated tests. The queries are checked by running `script/queries.rb` against the seed data.
- No authorization. Nothing yet checks who is asking for data. UUIDs make IDs hard to guess, but they don't control access.
- No pagination on the feed (see Future work).
- No audit history (see Open questions).
- No API or UI. This is a data layer only.

## How I used AI

I used Claude Code as a design partner.

- **Design.** I used brainstorming and "grill me" sessions to work through the data model before writing code. Examples: where the plan should live, how status gates access, which indexes the feed needs, and what changes at large scale. I made each decision listed above, and the open questions came out of those sessions.
- **Code.** Claude Code ran the Rails generators and wrote the files based on those decisions. I work mostly with Node ORMs like Prisma and Sequelize, so I paired with Claude to refresh my Rails and to see how familiar ORM patterns map to ActiveRecord.
- **Checking.** I ran every migration myself, tested the validations in the console, and checked each query's output against the seed data.
