# Sample data. Safe to run more than once: each record is looked up first
# and only created if it's missing.

basic   = Plan.find_or_create_by!(name: "basic")
premium = Plan.find_or_create_by!(name: "premium")

lee   = Provider.find_or_create_by!(email: "dr.lee@example.com")   { |p| p.first_name = "Dana";  p.last_name = "Lee" }
patel = Provider.find_or_create_by!(email: "dr.patel@example.com") { |p| p.first_name = "Priya"; p.last_name = "Patel" }

maria = Patient.find_or_create_by!(email: "maria@example.com") { |p| p.first_name = "Maria"; p.last_name = "Garcia" }
sam   = Patient.find_or_create_by!(email: "sam@example.com")   { |p| p.first_name = "Sam";   p.last_name = "Chen" }
jo    = Patient.find_or_create_by!(email: "jo@example.com")    { |p| p.first_name = "Jo";    p.last_name = "Rivera" }

# Maria: premium with Dr. Lee, basic with Dr. Patel. Sam: basic with Dr. Lee. Jo: no provider.
[
  [maria, lee,   premium],
  [maria, patel, basic],
  [sam,   lee,   basic]
].each do |patient, provider, plan|
  Subscription.find_or_create_by!(patient: patient, provider: provider) do |s|
    s.plan = plan
    s.status = "active"
  end
end

# Fixed times in the past so the newest-first order is easy to check.
entries = {
  maria => [
    [3.days.ago, "Had oatmeal and berries for breakfast."],
    [2.days.ago, "Skipped lunch, felt low energy by 3pm."],
    [1.hour.ago, "Tried the meal prep plan. Feeling better."]
  ],
  sam => [
    [4.days.ago, "First week tracking. Mostly takeout."],
    [1.day.ago,  "Cooked dinner twice this week."]
  ],
  jo => [
    [2.days.ago, "Not seeing anyone yet, just journaling."]
  ]
}

entries.each do |patient, list|
  next if patient.journal_entries.exists?

  list.each do |time, body|
    patient.journal_entries.create!(body: body, created_at: time, updated_at: time)
  end
end

puts "Seeded #{Provider.count} providers, #{Patient.count} patients, " \
     "#{Subscription.count} subscriptions, #{JournalEntry.count} journal entries."
