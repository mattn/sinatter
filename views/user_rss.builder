builder do |xml|
  xml.instruct! :xml, :version => '1.0'
  xml.rss :version => "2.0" do
    xml.channel do
      xml.title "#{@user}'s timeline"
      xml.description "#{@user}'s tweets timeline"
      xml.link "http://sinatter/user/#{@user}"
      
      @statuses.each do |status|
        xml.item do
          xml.title status.text
          xml.link "http://snatter/user/#{status.user}/#{status.id}"
          xml.description status.text
          xml.pubDate Time.parse(status.created_at.to_s).rfc822()
          xml.guid "http://snatter/user/#{status.user}/#{status.id}"
        end
      end
    end
  end
end
