# Runs the four required queries against the seed data.
# Usage: bin/rails db:seed && bin/rails runner script/queries.rb

lee   = Provider.find_by!(email: "dr.lee@example.com")
patel = Provider.find_by!(email: "dr.patel@example.com")
maria = Patient.find_by!(email: "maria@example.com")
jo    = Patient.find_by!(email: "jo@example.com")

def names(people) = people.map { |p| "#{p.first_name} #{p.last_name}" }.sort.join(", ")

def entries(list) = list.map { |e| "  #{e.created_at.strftime('%b %-d %H:%M')}  #{e.patient.first_name}: #{e.body}" }

puts "1. Active patients for Dr. Lee: #{names(lee.active_patients)}"
puts "   Active patients for Dr. Patel: #{names(patel.active_patients)}"
puts
puts "2. Active providers for Maria: #{names(maria.active_providers)}"
puts "   Active providers for Jo: #{names(jo.active_providers).presence || '(none)'}"
puts
puts "3. Maria's journal entries, newest first:"
puts entries(maria.journal_entries.newest_first.includes(:patient))
puts
puts "4. Dr. Lee's feed, newest first:"
puts entries(lee.journal_feed.includes(:patient))
puts
puts "   Dr. Patel's feed, newest first:"
puts entries(patel.journal_feed.includes(:patient))
