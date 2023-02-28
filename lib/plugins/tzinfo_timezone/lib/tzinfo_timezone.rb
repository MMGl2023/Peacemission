require 'tzinfo'

class TzinfoTimezone
  MAPPING = {
    "International Date Line West" => "Pacific/Midway",
    "Midway Island"                => "Pacific/Midway",
    "Samoa"                        => "Pacific/Pago_Pago",
    "Hawaii"                       => "Pacific/Honolulu",
    "Alaska"                       => "America/Juneau",
    "Pacific Time (US & Canada)"   => "America/Los_Angeles",
    "Tijuana"                      => "America/Tijuana",
    "Mountain Time (US & Canada)"  => "America/Denver",
    "Arizona"                      => "America/Phoenix",
    "Chihuahua"                    => "America/Chihuahua",
    "Mazatlan"                     => "America/Mazatlan",
    "Central Time (US & Canada)"   => "America/Chicago",
    "Saskatchewan"                 => "America/Regina",
    "Guadalajara"                  => "America/Mexico_City",
    "Mexico City"                  => "America/Mexico_City",
    "Monterrey"                    => "America/Monterrey",
    "Central America"              => "America/Guatemala",
    "Eastern Time (US & Canada)"   => "America/New_York",
    "Indiana (East)"               => "America/Indiana/Indianapolis",
    "Bogota"                       => "America/Bogota",
    "Lima"                         => "America/Lima",
    "Quito"                        => "America/Lima",
    "Atlantic Time (Canada)"       => "America/Halifax",
    "Caracas"                      => "America/Caracas",
    "La Paz"                       => "America/La_Paz",
    "Santiago"                     => "America/Santiago",
    "Newfoundland"                 => "America/St_Johns",
    "Brasilia"                     => "America/Argentina/Buenos_Aires",
    "Buenos Aires"                 => "America/Argentina/Buenos_Aires",
    "Georgetown"                   => "America/Argentina/San_Juan",
    "Greenland"                    => "America/Godthab",
    "Mid-Atlantic"                 => "Atlantic/South_Georgia",
    "Azores"                       => "Atlantic/Azores",
    "Cape Verde Is."               => "Atlantic/Cape_Verde",
    "Dublin"                       => "Europe/Dublin",
    "Edinburgh"                    => "Europe/Dublin",
    "Lisbon"                       => "Europe/Lisbon",
    "London"                       => "Europe/London",
    "Casablanca"                   => "Africa/Casablanca",
    "Monrovia"                     => "Africa/Monrovia",
    "Belgrade"                     => "Europe/Belgrade",
    "Bratislava"                   => "Europe/Bratislava",
    "Budapest"                     => "Europe/Budapest",
    "Ljubljana"                    => "Europe/Ljubljana",
    "Prague"                       => "Europe/Prague",
    "Sarajevo"                     => "Europe/Sarajevo",
    "Skopje"                       => "Europe/Skopje",
    "Warsaw"                       => "Europe/Warsaw",
    "Zagreb"                       => "Europe/Zagreb",
    "Brussels"                     => "Europe/Brussels",
    "Copenhagen"                   => "Europe/Copenhagen",
    "Madrid"                       => "Europe/Madrid",
    "Paris"                        => "Europe/Paris",
    "Amsterdam"                    => "Europe/Amsterdam",
    "Berlin"                       => "Europe/Berlin",
    "Bern"                         => "Europe/Berlin",
    "Rome"                         => "Europe/Rome",
    "Stockholm"                    => "Europe/Stockholm",
    "Vienna"                       => "Europe/Vienna",
    "West Central Africa"          => "Africa/Algiers",
    "Bucharest"                    => "Europe/Bucharest",
    "Cairo"                        => "Africa/Cairo",
    "Helsinki"                     => "Europe/Helsinki",
    "Kyev"                         => "Europe/Kiev",
    "Riga"                         => "Europe/Riga",
    "Sofia"                        => "Europe/Sofia",
    "Tallinn"                      => "Europe/Tallinn",
    "Vilnius"                      => "Europe/Vilnius",
    "Athens"                       => "Europe/Athens",
    "Istanbul"                     => "Europe/Istanbul",
    "Minsk"                        => "Europe/Minsk",
    "Jerusalem"                    => "Asia/Jerusalem",
    "Harare"                       => "Africa/Harare",
    "Pretoria"                     => "Africa/Johannesburg",
    "Moscow"                       => "Europe/Moscow",
    "St. Petersburg"               => "Europe/Moscow",
    "Volgograd"                    => "Europe/Moscow",
    "Kuwait"                       => "Asia/Kuwait",
    "Riyadh"                       => "Asia/Riyadh",
    "Nairobi"                      => "Africa/Nairobi",
    "Baghdad"                      => "Asia/Baghdad",
    "Tehran"                       => "Asia/Tehran",
    "Abu Dhabi"                    => "Asia/Muscat",
    "Muscat"                       => "Asia/Muscat",
    "Baku"                         => "Asia/Baku",
    "Tbilisi"                      => "Asia/Tbilisi",
    "Yerevan"                      => "Asia/Yerevan",
    "Kabul"                        => "Asia/Kabul",
    "Ekaterinburg"                 => "Asia/Yekaterinburg",
    "Islamabad"                    => "Asia/Karachi",
    "Karachi"                      => "Asia/Karachi",
    "Tashkent"                     => "Asia/Tashkent",
    "Chennai"                      => "Asia/Calcutta",
    "Kolkata"                      => "Asia/Calcutta",
    "Mumbai"                       => "Asia/Calcutta",
    "New Delhi"                    => "Asia/Calcutta",
    "Kathmandu"                    => "Asia/Katmandu",
    "Astana"                       => "Asia/Dhaka",
    "Dhaka"                        => "Asia/Dhaka",
    "Sri Jayawardenepura"          => "Asia/Dhaka",
    "Almaty"                       => "Asia/Almaty",
    "Novosibirsk"                  => "Asia/Novosibirsk",
    "Rangoon"                      => "Asia/Rangoon",
    "Bangkok"                      => "Asia/Bangkok",
    "Hanoi"                        => "Asia/Bangkok",
    "Jakarta"                      => "Asia/Jakarta",
    "Krasnoyarsk"                  => "Asia/Krasnoyarsk",
    "Beijing"                      => "Asia/Shanghai",
    "Chongqing"                    => "Asia/Chongqing",
    "Hong Kong"                    => "Asia/Hong_Kong",
    "Urumqi"                       => "Asia/Urumqi",
    "Kuala Lumpur"                 => "Asia/Kuala_Lumpur",
    "Singapore"                    => "Asia/Singapore",
    "Taipei"                       => "Asia/Taipei",
    "Perth"                        => "Australia/Perth",
    "Irkutsk"                      => "Asia/Irkutsk",
    "Ulaan Bataar"                 => "Asia/Ulaanbaatar",
    "Seoul"                        => "Asia/Seoul",
    "Osaka"                        => "Asia/Tokyo",
    "Sapporo"                      => "Asia/Tokyo",
    "Tokyo"                        => "Asia/Tokyo",
    "Yakutsk"                      => "Asia/Yakutsk",
    "Darwin"                       => "Australia/Darwin",
    "Adelaide"                     => "Australia/Adelaide",
    "Canberra"                     => "Australia/Melbourne",
    "Melbourne"                    => "Australia/Melbourne",
    "Sydney"                       => "Australia/Sydney",
    "Brisbane"                     => "Australia/Brisbane",
    "Hobart"                       => "Australia/Hobart",
    "Vladivostok"                  => "Asia/Vladivostok",
    "Guam"                         => "Pacific/Guam",
    "Port Moresby"                 => "Pacific/Port_Moresby",
    "Magadan"                      => "Asia/Magadan",
    "Solomon Is."                  => "Asia/Magadan",
    "New Caledonia"                => "Pacific/Noumea",
    "Fiji"                         => "Pacific/Fiji",
    "Kamchatka"                    => "Asia/Kamchatka",
    "Marshall Is."                 => "Pacific/Majuro",
    "Auckland"                     => "Pacific/Auckland",
    "Wellington"                   => "Pacific/Auckland",
    "Nuku'alofa"                   => "Pacific/Tongatapu"
  }

  attr_reader :name, :utc_offset

  # Create a new TzinfoTimezone object with the given name and offset. The
  # offset is the number of seconds that this time zone is offset from UTC
  # (GMT). Seconds were chosen as the offset unit because that is the unit that
  # Ruby uses to represent time zone offsets (see Time#utc_offset).
  def initialize(name, utc_offset)
    @name = name
    @utc_offset = utc_offset
  end

  # Returns the offset of this time zone as a formatted string, of the
  # format "+HH:MM". If the offset is zero, this returns the empty
  # string. If +colon+ is false, a colon will not be inserted into the
  # result.
  def formatted_offset(colon=true)
    utc_offset == 0 ? '' : offset(colon)
  end
  
  # Returns the offset of this time zone as a formatted string, of the
  # format "+HH:MM".
  def offset(colon=true)
    sign = (utc_offset < 0 ? -1 : 1)
    hours = utc_offset.abs / 3600
    minutes = (utc_offset.abs % 3600) / 60
    "%+03d%s%02d" % [ hours * sign, colon ? ":" : "", minutes ]
  end
  
  # Compute and return the current time, in the time zone represented by
  # +self+.
  def now
    tzinfo.now
  end

  # Return the current date in this time zone.
  def today
    now.to_date
  end

  # Adjust the given time to the time zone represented by +self+.
  def utc_to_local(time)
    tzinfo.utc_to_local(time)
  end

  def local_to_utc(time, dst=true)
    tzinfo.local_to_utc(time, dst)
  end

  # Adjust the given time to the time zone represented by +self+.
  # (Deprecated--use utc_to_local, instead.)
  alias :adjust :utc_to_local

  # Compare this time zone to the parameter. The two are comapred first on
  # their offsets, and then by name.
  def <=>(zone)
    result = (utc_offset <=> zone.utc_offset)
    result = (name <=> zone.name) if result == 0
    result
  end

  # Returns a textual representation of this time zone.
  def to_s
    "(GMT#{formatted_offset}) #{name}"
  end

  def tzinfo
    return @tzinfo if @tzinfo
    @tzinfo = MAPPING[name]
    if String === @tzinfo
      @tzinfo = TZInfo::Timezone.get(@tzinfo)
      MAPPING[name] = @tzinfo
    end
    @tzinfo
  end

  @@zones = nil

  class << self
    alias_method :create, :new

    # Return a TzinfoTimezone instance with the given name, or +nil+ if no
    # such TzinfoTimezone instance exists. (This exists to support the use of
    # this class with the #composed_of macro.)
    def new(name)
      self[name]
    end

    # Return an array of all TzinfoTimezone objects. There are multiple
    # TzinfoTimezone objects per time zone, in many cases, to make it easier
    # for users to find their own time zone.
    def all
      unless @@zones
        @@zones = []
        @@zones_map = {}
        [[-39_600, "International Date Line West", "Midway Island", "Samoa" ],
         [-36_000, "Hawaii" ],
         [-32_400, "Alaska" ],
         [-28_800, "Pacific Time (US & Canada)", "Tijuana" ],
         [-25_200, "Arizona"],
         [-25_200, "Mountain Time (US & Canada)"],
         [-25_200, "Chihuahua", "Mazatlan"],
         [-21_600, "Guadalajara", "Mexico City", "Monterrey"],
         [-21_600, "Saskatchewan"],
         [-21_600, "Central America" ],
         [-21_600, "Central Time (US & Canada)"],
         [-18_000, "Bogota", "Lima", "Quito" ],
         [-18_000, "Eastern Time (US & Canada)"],
         [-18_000, "Indiana (East)"],
         [-14_400, "Atlantic Time (Canada)"],
         [-14_400, "Caracas", "La Paz"],
         [-14_400, "Santiago" ],
         [-12_600, "Newfoundland" ],
         [-10_800, "Brasilia"],
         [-10_800, "Buenos Aires", "Georgetown"],
         [-10_800, "Greenland" ],
         [ -7_200, "Mid-Atlantic" ],
         [ -3_600, "Azores"],
         [ -3_600, "Cape Verde Is." ],
         [      0, "Dublin", "Edinburgh", "Lisbon", "London"],
         [      0, "Casablanca", "Monrovia" ],
         [  3_600, "Amsterdam", "Berlin", "Bern", "Rome", "Stockholm", "Vienna"],
         [  3_600, "Belgrade", "Bratislava", "Budapest", "Ljubljana", "Prague" ],
         [  3_600, "Brussels",  "Copenhagen", "Madrid", "Paris"],
         [  3_600, "Sarajevo", "Skopje", "Warsaw", "Zagreb"],
         [  3_600, "Sarajevo", "Skopje", "Warsaw", "Zagreb"],
         [  3_600, "West Central Africa" ],
         [  7_200, "Athens", "Istanbul", "Minsk"],
         [  7_200, "Bucharest"],
         [  7_200, "Helsinki", "Kyev", "Riga", "Sofia", "Tallinn", "Vilnius"],
         [  7_200, "Jerusalem"],
         [  7_200, "Cairo"],
         [  7_200, "Harare", "Pretoria" ],
         [ 10_800, "Baghdad" ],
         [ 10_800, "Kuwait", "Riyadh"],
         [ 10_800, "Moscow", "St. Petersburg", "Volgograd"],
         [ 10_800, "Nairobi"],
         [ 12_600, "Tehran" ],
         [ 14_400, "Abu Dhabi", "Muscat"],
         [ 14_400, "Baku", "Tbilisi", "Yerevan" ],
         [ 16_200, "Kabul" ],
         [ 18_000, "Ekaterinburg"],
         [ 18_000, "Islamabad", "Karachi", "Tashkent" ],
         [ 19_800, "Chennai", "Kolkata", "Mumbai", "New Delhi" ],
         [ 20_700, "Kathmandu" ],
         [ 21_600, "Astana", "Dhaka"],
         [ 21_600, "Almaty", "Novosibirsk" ],
         [ 21_600, "Sri Jayawardenepura"],
         [ 23_400, "Rangoon" ],
         [ 25_200, "Bangkok", "Hanoi", "Jakarta", "Krasnoyarsk" ],
         [ 25_200, "Krasnoyarsk" ],
         [ 28_800, "Beijing", "Hong Kong", "Urumqi"],
         [ 28_800, "Irkutsk", "Ulaan Bataar" ],
         [ 28_800, "Kuala Lumpur", "Singapore"],
         [ 28_800, "Perth"],
         [ 28_800, "Taipei"],
         [ 32_400, "Osaka", "Sapporo", "Tokyo"],
         [ 32_400, "Seoul"],
         [ 32_400, "Yakutsk" ],
         [ 34_200, "Adelaide" ],
         [ 34_200, "Darwin"],
         [ 36_000, "Brisbane"],
         [ 36_000, "Vladivostok"],
         [ 36_000, "Guam", "Port Moresby" ],
         [ 36_000, "Canberra", "Melbourne", "Sydney"],
         [ 36_000, "Hobart"],
         [ 39_600, "Magadan", "Solomon Is.", "New Caledonia" ],
         [ 43_200, "Fiji", "Kamchatka", "Marshall Is."],
         [ 43_200, "Auckland", "Wellington" ],
         [ 46_800, "Nuku'alofa" ]].
        each do |offset, *places|
          #places.each do |place|
#            zone = create(place, offset)
            #@@zones << zone
            #@@zones_map[place] = zone
          #end
          #place = places.join(", ")
          zone = create(places.join(", "), offset)
          @@zones << zone
          places.each do |place|
            @@zones_map[place] = zone
          end
        end
        @@zones.sort!
      end
      @@zones
    end

    # Locate a specific time zone object. If the argument is a string, it
    # is interpreted to mean the name of the timezone to locate. If it is a
    # numeric value it is either the hour offset, or the second offset, of the
    # timezone to find. (The first one with that offset will be returned.)
    # Returns +nil+ if no such time zone is known to the system.
    def [](arg)
      case arg
        when String
          all # force the zones to be loaded
          @@zones_map[arg]
        when Numeric
          arg *= 3600 if arg.abs <= 13
          all.find { |z| z.utc_offset == arg.to_i }
        else
          raise ArgumentError, "invalid argument to TzinfoTimezone[]: #{arg.inspect}"
      end
    end

    # A regular expression that matches the names of all time zones in
    # the USA.
    US_ZONES = /US|Arizona|Indiana|Hawaii|Alaska/

    # A convenience method for returning a collection of TzinfoTimezone objects
    # for time zones in the USA.
    def us_zones
      all.find_all { |z| z.name =~ US_ZONES }
    end
  end
end
