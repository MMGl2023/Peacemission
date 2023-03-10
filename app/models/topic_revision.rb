class TopicRevision < ActiveRecord::Base

  # serialize :topic_date

  belongs_to :author, class_name: 'User', foreign_key: 'author_id', optional: true
  belongs_to :topic, optional: true

  class << self
    def topic_data(topic)
      topic.attributes.except('id', 'rev')
    end

    def find_last(topic_id)
      self.order('rev DESC').find_by(topic_id: topic_id)
    end

    def find_last_by_name(name)
      self.order('created_at DESC').find_by(name: name)
    end

    def create_from_topic(topic)
      last_revision = find_last(topic)
      rev = last_revision ? last_revision.rev + 1 : 1
      revision = self.create(
        topic: topic,
        name: topic.name,
        author: topic.edited_by,
        topic_data: topic_data(topic).to_yaml.hex_decode,
        rev: rev
      )
    end

    def restore_topic(topic, rev)
      if revision = find_by_topic_id_and_rev(topic.id, rev)
        begin
          topic.attributes = YAML.load(revision.topic_data)
          topic.comment = "Restored from revision #{rev}"
          topic.restored
        rescue => e
          logger.info "Restoring topic error: #{e.message}"
          false
        end
      else
        false
      end
    end
  end
end
