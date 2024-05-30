# name: discourse-no-bump
# about: Discourse no bump plugin
# version: 0.2.1
# authors: Jiajun Du
# url: https://github.com/ShuiyuanSJTU/discourse-no-bump

enabled_site_setting :no_bump_enabled

register_svg_icon "user-secret" if respond_to?(:register_svg_icon)

load File.expand_path('../lib/discourse_no_bump/engine.rb', __FILE__)

after_initialize do

  Topic.register_custom_field_type('no_bump', :boolean)
  Topic.register_custom_field_type('hide_from_hot', :boolean)
  add_to_serializer :topic_view, :no_bump do
    object.topic.custom_fields['no_bump']
  end
  add_to_serializer :topic_view, :hide_from_hot do
    object.topic.custom_fields['hide_from_hot']
  end

  Discourse::Application.routes.append do
    mount ::DiscourseNoBump::Engine, at: "/no_bump"
  end

  module OverrideNoBumpWhenCreate
    def update_topic_stats
      attrs = { updated_at: Time.now }

      if @post.post_type != Post.types[:whisper] && !@opts[:silent]
        attrs[:last_posted_at] = @post.created_at
        attrs[:last_post_user_id] = @post.user_id
        attrs[:word_count] = (@topic.word_count || 0) + @post.word_count
        attrs[:excerpt] = @post.excerpt_for_topic if new_topic?
        # override here
        if !@topic.custom_fields['no_bump']
          attrs[:bumped_at] = @post.created_at unless @post.no_bump
        end
      end

      @topic.update_columns(attrs)
    end
  end

  module OverrideNoBumpWhenRevise
    def bump_topic
      # modify here
      return if bypass_bump? || !is_last_post? || @topic.custom_fields['no_bump']
      @topic.update_column(:bumped_at, Time.now)
      TopicTrackingState.publish_muted(@topic)
      TopicTrackingState.publish_unmuted(@topic)
      TopicTrackingState.publish_latest(@topic)
    end
  end

  module OverrideNoBumpWhenMove
    def update_last_post_stats
      post = destination_topic.ordered_posts.where.not(post_type: Post.types[:whisper]).last
      if post && post_ids.include?(post.id)
        attrs = {}
        attrs[:last_posted_at] = post.created_at
        attrs[:last_post_user_id] = post.user_id
        # modify here
        if !destination_topic.custom_fields['no_bump']
          attrs[:bumped_at] = Time.now
        end
        attrs[:updated_at] = Time.now
        destination_topic.update_columns(attrs)
      end
    end
  end

  module OverrideNoBumpMessageBus
    def publish_latest(topic, whisper = false)
      return if topic.custom_fields["no_bump"]
      super
    end
  end
  
  TopicTrackingState.singleton_class.prepend OverrideNoBumpMessageBus
  
  class ::PostCreator
    prepend OverrideNoBumpWhenCreate
  end

  class ::PostRevisor
    prepend OverrideNoBumpWhenRevise
  end

  class ::PostMover
    prepend OverrideNoBumpWhenMove
  end

  TopicQuery.add_custom_filter(:no_bump) do |results, topic_query|
    if topic_query.options[:no_bump] && topic_query.options[:no_bump] == 'true'
      results = results.joins("INNER JOIN topic_custom_fields ON topic_custom_fields.topic_id = topics.id").where("topic_custom_fields.name = 'no_bump' AND topic_custom_fields.value = 't'")
    end
    results
  end

  register_modifier(:topic_query_create_list_topics) do |topics, options, topic_query|
    next topics unless options[:filter] == :hot
    topics = topics.where(<<~SQL)
      topics.id NOT IN (
        SELECT topic_id FROM topic_custom_fields 
        WHERE (name = 'no_bump' AND value = 't')
        OR (name = 'hide_from_hot' AND value = 't')
      )
    SQL
    if SiteSetting.hide_closed_topics_in_hot_topics
      topics = topics.where(closed:false)
    end
    topics
  end
end
