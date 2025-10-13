# frozen_string_literal: true

module DiscourseNoBump
  class NoBumpController < ApplicationController
    requires_plugin DiscourseNoBump

    requires_login

    before_action :ensure_staff

    def ensure_staff
      unless current_user.has_trust_level?(TrustLevel[4]) || current_user.staff?
        raise Discourse::InvalidAccess.new
      end
    end

    def enable
      t = Topic.find(params[:topic_id])
      if current_user.has_trust_level?(TrustLevel[4]) || current_user.staff?
        t.custom_fields["no_bump"] = true
        t.save_custom_fields
        render json: { no_bump_enabled: true }
      else
        render json: { failed: "Access denied" }, status: :forbidden
      end
    end

    def disable
      t = Topic.find(params[:topic_id])
      if current_user.has_trust_level?(TrustLevel[4]) || current_user.staff?
        t.custom_fields["no_bump"] = nil
        t.save_custom_fields
        render json: { no_bump_enabled: false }
      else
        render json: { failed: "Access denied" }, status: :forbidden
      end
    end

    def hide_from_hot_enabled
      t = Topic.find(params[:topic_id])
      if current_user.has_trust_level?(TrustLevel[4]) || current_user.staff?
        t.custom_fields["hide_from_hot"] = true
        t.save_custom_fields
        render json: { hide_from_hot_enabled: true }
      else
        render json: { failed: "Access denied" }, status: :forbidden
      end
    end

    def hide_from_hot_disabled
      t = Topic.find(params[:topic_id])
      if current_user.has_trust_level?(TrustLevel[4]) || current_user.staff?
        t.custom_fields["hide_from_hot"] = nil
        t.save_custom_fields
        render json: { hide_from_hot_enabled: false }
      else
        render json: { failed: "Access denied" }, status: :forbidden
      end
    end
  end
end
