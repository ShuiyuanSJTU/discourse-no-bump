import Component from "@ember/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class NoBumpTopicBanner extends Component {
  <template>
    {{#if this.model.no_bump}}
      <div class="row">
        <div class="post-notice custom">
          {{icon "user-secret"}}
          <div>
            <p>{{i18n "no_bump.topic_banner"}}</p>
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
