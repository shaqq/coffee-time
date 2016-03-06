require "sendgrid-ruby"

def send_emails(recipients)
  recipient_names = recipients.map(&:first)
  recipient_first_names = recipient_names.map { |n| n.split.first }
  recipient_first_names_human = recipient_first_names.join(' & ')

  recipient_emails = recipients.map(&:last)

  reply_to = recipient_emails

  message = SendGrid::Mail.new({
   "text"=> "#{recipient_first_names_human},

You're matched up! Plan to meet for about half an hour and please reschedule if you have a conflict.

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
