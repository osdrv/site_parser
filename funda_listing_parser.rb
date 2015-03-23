require 'digest/sha1'

class FundaListingParser
  
  class << self
    
    def listing_element_css
      'ul.object-list li.nvm'
    end
    
    def parse_slop(slop)
      res = {}
      %w(
        id
        address
        url
        img_src
        price
        visiting
        since
      ).map { |a| a.to_sym }.each do |attr|
        res[attr] = self.send(attr, slop)
      end
      
      res
    end
    
    def address(slop)
      slop.at_css('a.object-street').content.strip
    end
    
    def id(slop)
      Digest::SHA1.hexdigest url(slop)
    end
    
    def url(slop)
      slop.at_css('a.object-media-wrapper').attribute('href').value
    end
    
    def img_src(slop)
      (slop.at_css('a img.photo') ||
        slop.at_css('a span img.object-images')).attribute('src').value
    end
    
    def price(slop)
      slop.at_css('span.price-wrapper span.price').content
    end
    
    def visiting(slop)
      (slop.css('span.nvm-open-huizen-dag span') || []).map { |el| el.content }.join(', ')
    end
    
    def since(slop)
      slop.at_css('span.item-since').content
    end
    
  end

end