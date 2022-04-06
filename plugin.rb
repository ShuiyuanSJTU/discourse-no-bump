# name: discourse-no-bump
# about: Discourse no bump plugin
# version: 0.1
# authors: Jiajun Du
# url: https://github.com/dujiajun/discourse-no-bump

enabled_site_setting :no_bump_enabled

register_svg_icon "user-secret" if respond_to?(:register_svg_icon)

load File.expand_path('../lib/discourse_no_bump/engine.rb', __FILE__)

after_initialize do

  Topic.register_custom_field_type('no_bump', :boolean)
  add_to_serializer :topic_view, :no_bump do
    object.topic.custom_fields['no_bump'] 
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
        if !@topic.custom_fields['no_bump'] 
          attrs[:bumped_at] = @post.created_at unless @post.no_bump
        end
      end
  
      @topic.update_columns(attrs)
    end
  end

  module OverrideNoBumpWhenRevise
    def bump_topic
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
        if !destination_topic.custom_fields['no_bump'] 
          attrs[:bumped_at] = Time.now
        end
        attrs[:updated_at] = Time.now
        destination_topic.update_columns(attrs)
      end
    end
  end

  class ::PostCreator
    prepend OverrideNoBumpWhenCreate
  end

  class ::PostRevisor
    prepend OverrideNoBumpWhenRevise
  end

  class ::PostMover
    prepend OverrideNoBumpWhenMove
  end
end

