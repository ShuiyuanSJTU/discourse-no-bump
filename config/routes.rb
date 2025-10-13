# frozen_string_literal: true

DiscourseNoBump::Engine.routes.draw do
  put "/enable" => "no_bump#enable"
  put "/disable" => "no_bump#disable"
  put "/hide_from_hot/enable" => "no_bump#hide_from_hot_enabled"
  put "/hide_from_hot/disable" => "no_bump#hide_from_hot_disabled"
end
