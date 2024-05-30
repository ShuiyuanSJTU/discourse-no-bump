import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

function registerTopicFooterButtons(api) {
  const currentUser = api.getCurrentUser();
  if (!(currentUser && (currentUser.trust_level == 4 || currentUser.staff)))
    return;
  api.addTopicAdminMenuButton((topic) => {
    return {
      id: "no-bump",
      get icon() {
        const noBump = topic.get("no_bump");
        return noBump ? "angle-up" : "angle-down";
      },
      get label() {
        const noBump = topic.get("no_bump");
        return `no_bump.button.${noBump ? "allow_bump" : "no_bump"}.button`;
      },
      action() {
        if (!topic.get("user_id")) {
          return;
        }

        var action = topic.get("no_bump") ? "disable" : "enable";

        return ajax("/no_bump/" + action + ".json", {
          type: "PUT",
          data: { topic_id: topic.get("id") },
        })
          .then((result) => {
            topic.set("no_bump", result.no_bump_enabled);
          })
          .catch(popupAjaxError);
      },
      classNames: ["no-bump"],
    }
  });
  api.addTopicAdminMenuButton((topic) => {
    return {
      id: "hide-from-hot",
      get icon() {
        const hide_from_hot = topic.get("hide_from_hot");
        return hide_from_hot ? "far-eye" : "far-eye-slash";
      },
      title() {
        const hide_from_hot = topic.get("hide_from_hot");
        return `hide_from_hot.button.${hide_from_hot ? "show" : "hide"}.help`;
      },
      get label() {
        const hide_from_hot = topic.get("hide_from_hot");
        return `hide_from_hot.button.${hide_from_hot ? "show" : "hide"}.button`;
      },
      action() {
        if (!topic.get("user_id")) {
          return;
        }

        var action = topic.get("hide_from_hot") ? "disable" : "enable";

        return ajax("/no_bump/hide_from_hot/" + action + ".json", {
          type: "PUT",
          data: { topic_id: topic.get("id") },
        })
          .then((result) => {
            topic.set("hide_from_hot", result.hide_from_hot_enabled);
          })
          .catch(popupAjaxError);
      },
      classNames: ["hide-from-hot"],
    }
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
