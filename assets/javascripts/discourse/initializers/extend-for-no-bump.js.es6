import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

function registerTopicFooterButtons(api) {
  api.registerTopicFooterButton({
    id: "no-bump",
    icon() {
      const noBump = this.get("topic.no_bump");
      return noBump ? "angle-up" : "angle-down";
    },
    title() {
      const noBump = this.get("topic.no_bump");
      return `no_bump.button.${noBump ? "allow_bump" : "no_bump"}.help`;
    },
    label() {
      const noBump = this.get("topic.no_bump");
      return `no_bump.button.${noBump ? "allow_bump" : "no_bump"}.button`;
    },
    action() {
      if (!this.get("topic.user_id")) {
        return;
      }

      var action = this.get("topic.no_bump") ? "disable" : "enable";

      return ajax("/no_bump/" + action + ".json", {
        type: "PUT",
        data: { topic_id: this.get("topic.id") },
      })
        .then((result) => {
          this.set("topic.no_bump", result.no_bump_enabled);
        })
        .catch(popupAjaxError);
    },
    dropdown() {
      return this.site.mobileView;
    },
    classNames: ["no-bump"],
    dependentKeys: ["topic.no_bump"],
    displayed() {
      return (
        this.currentUser &&
        (this.currentUser.trust_level == 4 || this.currentUser.staff)
      );
    },
  });
}

export default {
  name: "extend-for-no-bump",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    if (!siteSettings.no_bump_enabled) {
      return;
    }

    withPluginApi("0.8.28", (api) =>
      registerTopicFooterButtons(api, container)
    );
  },
};
