# frozen_string_literal: true

module ::DiscourseNoBump
  class Engine < ::Rails::Engine
    engine_name "discourse_no_bump"
    isolate_namespace DiscourseNoBump
  end
end
