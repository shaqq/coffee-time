require "base64"
require "mandrill"

# recipients is an array of name email pairs
# [
#   ["Daniel", "danielx@fogcreek.com"]
#   ...
# ]

def send_emails(recipients)
  recipients.each do |person|
    others = (recipients - [person])
    others_names = others.map do |person|
      "#{person.first} (#{person.last})"
    end.join " and "
    # TODO: Can't get multi-way reply-to working
    # this will cover it for 90% of the time
    reply_to = others.first.last
    email = person.last

    message = {
     "text"=> "This week you're meeting with #{others_names} on Wednesday 12pm EST.

Get to know your coworkers. Meet up in person or over a hangout, grab a coffee, and chat. Plan to meet for about half an hour and please reschedule if you have a conflict.

Enjoy!

Email shaker@bellycard.com with questions, comments or suggestions for Graymalkin CoffeeTime.
",
   "subject"=> "Graymalkin CoffeeTime - #{recipient_first_names_human}",
   "from"=> "shaker@bellycard.com",
   "from_name"=> "Shaker Islam",
   "to" => recipient_emails,
   "reply_to" => reply_to
  })

  sendgrid = SendGrid::Client.new api_key: ENV['SENDGRID_APIKEY']

  begin
    result = sendgrid.send(message)
  rescue => e
    $REDIS.rpush "retries", {recipients: recipients}.inspect
    puts "A sendgrid error occurred: #{e.class} - #{e.message}"
  end
end
