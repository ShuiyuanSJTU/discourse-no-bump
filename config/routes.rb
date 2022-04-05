
DiscourseNoBump::Engine.routes.draw do
  put "/enable" => "no_bump#enable"
  put "/disable" => "no_bump#disable"
end

