class EmailTmplFunda
  
  class << self
    
    def render(channel, items)
      msg = ''
      
      header = <<END_OF_MESSAGE
<html>
<body>
  <h1>Good news everyone!</h1>
  <h4>I've found some new apartmens for you! Check them out!</h4>
  <ul>
END_OF_MESSAGE

      items.each do |item|
        item_body = <<EOM
<li style="padding: 10px; border-bottom: 1px dotted #00F">
  <div><a href="http://funda.nl#{item[:url]}">#{item[:address]}</a></div>
  <div>
    <img src=#{item[:img_src]}>
  </div>
  <div>Price: #{item[:price]}</div>
  <div>Since: #{item[:since]}</div>
  <div>Visiting: #{item[:visiting]}</div>
</li>
EOM
        msg += item_body
      end

      footer = <<EOM
  </ul>
  <div>
    <a href="#{channel}">Don't hesitate to visit the website. I might have missed something.</a>
  </div>
  <span>Best regards, your lovely robot.</span>
</body>
</html>      
EOM

      header + msg + footer
    end
    
  end
  
end