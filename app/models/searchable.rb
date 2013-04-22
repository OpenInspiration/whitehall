module Searchable
  extend ActiveSupport::Concern

  SEARCH_FIELDS = [
    :id, :title, :link, :content,
    :section, :subsection, :subsubsection,
    :format, :boost_phrases, :description,
    :organisations, :public_timestamp,
    :people, :publication_type, :speech_type,
    :topics, :news_article_type, :display_type,
    :relevant_to_local_government,
    :search_format_types, :world_locations
  ]

  included do
    class_attribute :searchable_options
  end

  module ClassMethods
    def searchable(options)
      include Searchable::Mixin

      self.searchable_options = options.reverse_merge \
        format:         -> o { o.class.model_name.element },
        index_after:    :save,
        unindex_after:  :destroy,
        only:           :scoped,
        description:    ""

      self.searchable_options[:index_after] = [self.searchable_options[:index_after]].flatten.select { |e| e }
      self.searchable_options[:unindex_after] = [self.searchable_options[:unindex_after]].flatten.select { |e| e }

      (SEARCH_FIELDS + [:only]).each do |name|
        value = searchable_options[name]
        searchable_options[name] =
          if value.respond_to?(:call)
            # use procs verbatim
            value
          elsif value.respond_to?(:to_proc)
            # turn willing objects (e.g. symbols) into procs
            value.to_proc
          else
            # treat other objects (e.g. strings) as constants
            -> _ { value }
          end
      end

      searchable_options[:index_after].each do |event|
        set_callback event, :after, :update_in_search_index
      end
      searchable_options[:unindex_after].each do |event|
        set_callback event, :after, :remove_from_search_index
      end
    end
  end

  module Mixin
    extend ActiveSupport::Concern

    KEY_MAPPING = {
      content: 'indexable_content'
    }

    def search_index
      SEARCH_FIELDS.inject({}) do |result, name|
        value = searchable_options[name].call(self)
        key = KEY_MAPPING[name] || name.to_s
        result[key] = value unless value.nil?
        result
      end
    end

    def can_index_in_search?
      searchable_options[:only].call(self.class).find_by_id(self.id).present? && Whitehall.searchable_classes.include?(self.class)
    end

    def update_in_search_index
      if can_index_in_search?
        Searchable::Index.later(self)
      end
    end

    def remove_from_search_index
      Searchable::Delete.later(self)
    end

    def rummager_index
      is_a?(DetailedGuide) ? Whitehall.detailed_guidance_search_index_path : Whitehall.government_search_index_path
    end

    module ClassMethods
      def reindex_all
        if Whitehall.searchable_classes.include?(self)
          searchable_instances.each do |instance|
            Searchable::Index.later(instance)
          end
        end
      end
      def searchable_instances
        searchable_options[:only].call(self)
      end
      def search_index
        Enumerator.new do |y|
          searchable_instances.find_each do |edition|
            y << edition.search_index
          end
        end
      end
    end
  end

  class Index < Struct.new(:searchable_class_name, :searchable_id)
    def allowed_class_names
      Whitehall.searchable_classes.map(&:name)
    end
    def searchable_class
      if allowed_class_names.include?(searchable_class_name)
        searchable_class_name.constantize
      else
        raise ArgumentError, "#{searchable_class_name} is not an allowed class for searching"
      end
    end

    def searchable_instance
      @searchable_instance ||= searchable_class.find(searchable_id)
    end

    def self.later(object)
      Delayed::Job.enqueue new(object.class.name, object.id)
    end

    def perform
      if searchable_instance.can_index_in_search?
        Rummageable.index(searchable_instance.search_index, searchable_instance.rummager_index)
      end
    end
  end

  class Delete < Struct.new(:link, :index)
    def self.later(object)
      Delayed::Job.enqueue new(object.searchable_options[:link].call(object), object.rummager_index)
    end

    def perform
      Rummageable.delete(link, index)
    end
  end
end
