import { apiInitializer } from "discourse/lib/api";
import { addGlobalNotice } from "discourse/components/global-notice";
import { i18n } from "discourse-i18n";

const PROVIDER_NAMES = {
  apple: "Apple",
  discord: "Discord",
  facebook: "Facebook",
  github: "GitHub",
  google_oauth2: "Google",
  linkedin_oidc: "LinkedIn",
  twitter: "Twitter/X"
};

export default apiInitializer(async (api) => {
  const currentUser = api.getCurrentUser();

  if (!currentUser) {
    return;
  }

  const deprecatedProviders = [];
  if (settings.apple) deprecatedProviders.push("apple");
  if (settings.discord) deprecatedProviders.push("discord");
  if (settings.facebook) deprecatedProviders.push("facebook");
  if (settings.github) deprecatedProviders.push("github");
  if (settings.google) deprecatedProviders.push("google_oauth2");
  if (settings.linkedin) deprecatedProviders.push("linkedin_oidc");
  if (settings.twitter) deprecatedProviders.push("twitter");

  if (deprecatedProviders.length === 0) {
    return;
  }

  // This will fetch the user's associated_accounts (among other things)
  await currentUser.checkEmail();

  if (!currentUser.associated_accounts) {
    return;
  }

  const deprecated = currentUser.associated_accounts.filter(({ name }) => deprecatedProviders.includes(name));
  const hasDiscourseId = currentUser.associated_accounts.some(({ name }) => name === "discourse_id");

  if (deprecated.length > 0 && !hasDiscourseId) {
    const providers = deprecated.map(({ name })=> PROVIDER_NAMES[name] || name).join(", ");

    let message;

    if (settings.deprecation_date) {
      const date = moment(settings.deprecation_date).format("LL");
      message = i18n(themePrefix("social_logins_deprecation.notice_with_date"), { providers, date });
    } else {
      message = i18n(themePrefix("social_logins_deprecation.notice"), { providers });
    }

    // TODO: does it make sense to show the notice when any settings changes?
    addGlobalNotice(message, "social-logins-deprecations", { dismissable: true });
  }
});
