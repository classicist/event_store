module EventStore
  class TimeHacker
    class << self
      #Hack around various DB adapters that hydrate dates from the db into the local ruby timezone
      def translate_occurred_at_from_local_to_gmt(occurred_at)
        if occurred_at.class == Time
          #expecting "2001-02-03 01:26:40 -0700"
          Time.parse(occurred_at.to_s.gsub(/\s[+-]\d+$/, ' UTC'))
        elsif occurred_at.class == DateTime
          #expecting "2001-02-03T01:26:40+00:00"
          Time.parse(occurred_at.iso8601.gsub('T', ' ').gsub(/[+-]\d{2}\:\d{2}/, ' UTC'))
        end
      end
    end
  end
end