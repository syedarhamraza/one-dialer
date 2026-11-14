// The release switch. While false, the site is the closed beta's: it asks people to join the test in two steps.
// Set it to true the day One Dialer is public on Google Play: the Beta badge, the join steps and the beta
// questions go, and every call to action becomes a Get it on Google Play button.
export const RELEASED = false;

export const GROUP_URL = "https://groups.google.com/g/one-dialer-closedbeta";
export const TESTING_URL = "https://play.google.com/apps/testing/com.syedarhamraza.onedialer";
export const PLAY_URL = "https://play.google.com/store/apps/details?id=com.syedarhamraza.onedialer";
export const REPO_URL = "https://github.com/syedarhamraza/one-dialer";
export const EMAIL = "arhamraza399@gmail.com";
// Every GitHub release carries the recorder under this name and none is marked pre-release, so this is always the newest.
export const RECORDER_URL = `${REPO_URL}/releases/latest/download/one-dialer-recorder.apk`;
// Open GitHub's issue form straight on the repo's templates (.github/ISSUE_TEMPLATE).
export const BUG_URL = `${REPO_URL}/issues/new?template=bug_report.yml`;
export const FEATURE_URL = `${REPO_URL}/issues/new?template=feature_request.yml`;
