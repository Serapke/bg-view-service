module GroupPicks
  class Serializer
    def self.serialize(picks)
      { picks: picks.map { |p| serialize_pick(p) } }
    end

    def self.serialize_pick(pick)
      {
        game:              pick[:game],
        score:             pick[:score],
        owned_by_host_ids: pick[:owned_by_host_ids],
        is_extra:          pick[:is_extra]
      }
    end
  end
end
