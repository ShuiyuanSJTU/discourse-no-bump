# frozen_string_literal: true

module DiscourseNoBump
  class NoBumpController < ApplicationController
    requires_login

    def enable
      t = Topic.find(params[:topic_id])
      if current_user.id == t.user_id || current_user.staff?
        t.custom_fields['no_bump'] = true
        t.save!
        render json: { no_bump_enabled: true }
      else
        render json: { failed: 'Access denied' }, status: 403
      end
    end

    def disable
      t = Topic.find(params[:topic_id])
      if current_user.staff?
        t.custom_fields['no_bump'] = false
        t.save!
        render json: { no_bump_enabled: false }
      else
        render json: { failed: 'Access denied' }, status: 403
      end
    end
  end
end

