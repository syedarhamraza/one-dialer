# Switching on the release pipeline (go-public day)

Everything the pipeline needs is already in the repo. This guide is the one-time setup that turns it on, done on the day the repo goes public. Do the steps in order; each ends with a check. About an hour.

Commands are for PowerShell, run from `D:\dialer`. `gh` is the GitHub CLI, signed in as the repo owner (`gh auth status`).

No secret is ever written in this file, in chat, or on a command line. Passwords are pasted into `gh`'s hidden prompt; files are piped straight from disk.

## What exists, and what is waiting

| Piece | File | Before this guide | After |
|---|---|---|---|
| Checks on every pull request, plus a debug APK to download | `.github/workflows/ci.yml` | Working | Working |
| Draft release notes from merged pull requests | `.github/workflows/release-drafter.yml` | Working | Working |
| Website build | `.github/workflows/pages.yml` | Builds, never deploys (private repo) | Deploys to `syedarhamraza.github.io/one-dialer/` |
| Release | `.github/workflows/release.yml` | Stops at "no secrets yet" | One button to Play, GitHub Releases and the website |

Until the switch, a release is still `./tool/release.ps1` on the PC (see [play-release.md](play-release.md)). One thing changed: the notes land in `site/public/changelog.json` in this repo. While the old site is still the live one, copy that file to `D:\syedarhamraza.github.io\public\one-dialer\changelog.json` and push that repo, as before.

## 0. The day before

1. Nothing private is about to become public. Look at what is on GitHub, not only at your disk:

   ```powershell
   gh api repos/syedarhamraza/one-dialer/branches --paginate --jq '.[].name'
   ```

   Only `main`, `beta/<n>` and open work branches should be listed. No `private/*`, no `showcase-build`.
2. No real phone numbers, names, keystores or `key.properties` in the history. `git log --all --stat -- "*.jks" "*.keystore" android/key.properties` must print nothing.
3. You have at hand: the upload keystore file, its two passwords and alias (they are in `android/key.properties`), and `android/app/google-services.json`.
4. No release is half done: `git status` is clean, the last release's tag is pushed.

## 1. Make the repo public

```powershell
gh repo edit syedarhamraza/one-dialer --visibility public --accept-visibility-change-consequences
```

Check: `gh repo view syedarhamraza/one-dialer --json visibility` prints `PUBLIC`.

## 2. Turn on the website

1. Enable Pages, built by Actions:

   ```powershell
   gh api -X POST repos/syedarhamraza/one-dialer/pages -f build_type=workflow
   ```

2. Let the beta branch deploy. GitHub > the repo > **Settings > Environments > github-pages > Deployment branches and tags**. It lists only the default branch. Add two rules: `main` and `beta/*`.
3. Deploy once by hand, from the current beta branch:

   ```powershell
   gh workflow run pages.yml --ref beta/8
   gh run watch
   ```

   (`gh run watch` asks which run; pick "Website".)
4. Check all three addresses the app depends on. Each must print `200`:

   ```powershell
   foreach ($p in '', 'privacy/', 'changelog.json') { curl.exe -s -o NUL -w "%{http_code} $p`n" "https://syedarhamraza.github.io/one-dialer/$p" }
   ```

5. Check it is **this** repo answering, not the old site: the page's `last-modified` is a few minutes old.

   ```powershell
   curl.exe -sI https://syedarhamraza.github.io/one-dialer/ | Select-String last-modified
   ```

   If the date is old, wait five minutes and try again (GitHub's cache). If it stays old, stop here and do not do step 3: the old site keeps everything working while you look into it.

## 3. Remove the old copy from the website repo

Only after step 2's checks pass. In `D:\syedarhamraza.github.io`:

```powershell
git rm -r app/one-dialer public/one-dialer content/one-dialer-privacy-policy.md scripts/sync-one-dialer.mjs
```

Then by hand, in the same repo:

- `package.json`: delete the `"sync:dialer"` line.
- Any link to One Dialer on the One Spend pages (search for `one-dialer`): make it a plain `<a href="/one-dialer/">`, not a Next `<Link>`, because the page now belongs to another site.
- `README.md`: drop the One Dialer section.

`npm run build`, commit, push. Check: step 2.4's three addresses still print `200` after that repo's deploy finishes.

From now on the site's source is `site/` here. Screenshots: `cd site; npm run sync`.

## 4. The approval gate

GitHub > the repo > **Settings > Environments > New environment**, name it exactly `release`.

1. **Required reviewers**: tick it, add yourself.
2. **Prevent self-review**: leave it **off**. You start the release and you approve it; with this on, nobody could.
3. **Deployment branches and tags**: Selected branches and tags, add `main` and `beta/*`.
4. Save protection rules.

Check: `gh api repos/syedarhamraza/one-dialer/environments/release --jq '.protection_rules[].type'` prints `required_reviewers` and `branch_policy`.

## 5. A Google account for the pipeline

One service account does both jobs: uploading to Play and sending crash symbols to Firebase.

1. [Google Cloud Console](https://console.cloud.google.com/) > pick the **same project as One Dialer's Firebase** (top bar).
2. **APIs & Services > Library** > search "Google Play Android Developer API" > **Enable**.
3. **IAM & Admin > Service Accounts > Create service account**. Name: `play-release`. Role: **Firebase Crashlytics Admin**. Done.
4. Open the new account > **Keys > Add key > Create new key > JSON**. A file downloads; say it is `C:\Users\YOU\Downloads\play-release.json`. Copy the account's email (`play-release@....iam.gserviceaccount.com`).
5. [Play Console](https://play.google.com/console) > **Users and permissions > Invite new users**. Email: the service account's. **App permissions** > add One Dialer > tick **Release apps to testing tracks** and **Release to production, exclude devices, and use Play App Signing** (the second is what lets a production build be uploaded as a draft). Invite user.

Check: the account shows as Active under Users and permissions. Play can take from a few minutes to a day to honour a new service account; if step 8 fails with "The caller does not have permission", that is the reason.

## 6. The secrets

Seven, all on the `release` environment, so only an approved release job can read them. Run each line; where it says **prompt**, `gh` asks for the value with hidden input: paste it and press Enter.

```powershell
$repo = 'syedarhamraza/one-dialer'

# The upload keystore, as text. Put your keystore's real path here (storeFile in android/key.properties).
[Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\Users\YOU\keys\onedialer-upload.jks')) | gh secret set UPLOAD_KEYSTORE_B64 --env release -R $repo

# Prompt: paste exactly what follows "=" in android/key.properties for each.
gh secret set UPLOAD_STORE_PASSWORD --env release -R $repo
gh secret set UPLOAD_KEY_PASSWORD --env release -R $repo
gh secret set UPLOAD_KEY_ALIAS --env release -R $repo

# Files, piped from disk.
Get-Content -Raw android\app\google-services.json | gh secret set GOOGLE_SERVICES_JSON --env release -R $repo
Get-Content -Raw C:\Users\YOU\Downloads\play-release.json | gh secret set PLAY_SERVICE_ACCOUNT_JSON --env release -R $repo
```

Then delete the downloaded key: `Remove-Item C:\Users\YOU\Downloads\play-release.json`. GitHub has it now, and it can't be read back from there; make a new key in step 5.4 if it is ever needed again.

The seventh, `RELEASE_DEPLOY_KEY`, comes from step 7.

Check: `gh secret list --env release -R $repo` lists six names (seven after step 7). Values are never shown.

What is **not** here: the Play app-signing key. Google holds it and never hands it out. The recorder trusts Play installs by that key's certificate hash, which is public and already in `companion/.../TrustedDialer.kt`.

## 7. Let the workflow push the release commit

The `protect main and beta` ruleset blocks direct pushes, and the release commit and tag are a direct push. A deploy key on the ruleset's bypass list is the one exception.

1. Make a key pair. Press Enter twice when asked for a passphrase (it must be empty):

   ```powershell
   ssh-keygen -t ed25519 -C one-dialer-release -f "$env:TEMP\od-release"
   ```

2. Public half to the repo, with write access; private half to the secrets; then delete both files:

   ```powershell
   gh repo deploy-key add "$env:TEMP\od-release.pub" --allow-write --title release-workflow -R $repo
   Get-Content -Raw "$env:TEMP\od-release" | gh secret set RELEASE_DEPLOY_KEY --env release -R $repo
   Remove-Item "$env:TEMP\od-release", "$env:TEMP\od-release.pub"
   ```

3. GitHub > **Settings > Rules > Rulesets > protect main and beta > Bypass list > Add bypass > Deploy keys**. Mode: Always. Save.

Check: `gh api repos/syedarhamraza/one-dialer/rulesets --jq '.[0].id'` gives an id; `gh api repos/syedarhamraza/one-dialer/rulesets/<id> --jq '.bypass_actors[].actor_type'` lists `DeployKey`.

## 8. First run

A test that reaches nobody but you: re-upload the current version to the **internal** track.

1. GitHub > **Actions > Release > Run workflow**. Branch: `beta/8`. Version step: `rebuild`. Track: `internal`. Run.
2. The run stops at "Waiting for review". **Review deployments > release > Approve and deploy**. (The GitHub phone app shows the same button.)
3. About 20 minutes. Then check:

   | Where | What you should see |
   |---|---|
   | The run | Every step green |
   | `git pull` on `beta/8` | A `chore(release): <name> (<build>)` commit with the build number one higher |
   | Play Console > Testing > Internal testing | That build number, with "What's new" filled in |
   | GitHub > Releases | `One Dialer <name>` with `one-dialer-recorder.apk` and a `symbols-...zip` |
   | `https://syedarhamraza.github.io/one-dialer/changelog.json` | `"code"` is the new build number (give the Website run two minutes) |
   | Firebase > Crashlytics | No "missing symbols" warning for the new build |
   | A phone with One Dialer from Play, on the internal track | Settings > Software update offers the build and shows its notes |

`rebuild` keeps the version name and its existing notes, so this run ships whatever is on the beta branch under the current name. That is fine on the internal track.

## Every release after that

1. **Notes.** GitHub > Releases > the draft called "Next release". Release Drafter has listed every merged pull request under New and Fixed. Rewrite the lines into what a user should read, delete the ones users don't care about, keep each as one `- ` line. Save draft. Do this last, after the final merge: any later merge rewrites the draft from the pull request titles. (Titles written for users from the start need no editing.)
2. **Run.** Actions > Release > Run workflow on the beta branch. Version step and track:

   | You want | Version step | Track |
   |---|---|---|
   | The next beta to closed testers | `next-beta` | `alpha` |
   | The same to open testing | `next-beta` | `beta` |
   | The real release | `promote` | `production` (uploaded as a draft; roll it out in Play Console) |
   | A fix after release | `patch` | `production` |
   | Upload failed, try again | `rebuild` | same as before |

3. **Approve.**
4. **Afterwards**, as always: open the `beta/<n>` to `main` pull request, merge it once the beta has shipped, cut `beta/<n+1>`.

How the version moves is in [play-release.md](play-release.md#versioning).

## When something fails

| What you see | Why | Do |
|---|---|---|
| "The release environment has no secrets yet" | Step 6 isn't done, or the secrets were set on the repo instead of the `release` environment | Step 6, with `--env release` |
| "No '- ' lines in ... notes.md" | The draft release is empty or has no `- ` lines, and the Changelog has no entry for this version | Edit the draft (or write the entry in `lib/core/config/changelog.dart`), run again. Nothing was changed |
| Fails in "Version, build and sign" on analyze or tests | The branch is broken | Fix it with a normal pull request, run again. Nothing was changed |
| "Keystore was tampered with, or password was incorrect" | A password secret is wrong, or has a `\` in it (Java reads `\` in `key.properties` as an escape; write it as `\\` in the secret) | Set the secret again, run again |
| Push rejected: "repository rule violations" | The deploy key isn't on the ruleset's bypass list | Step 7.3, then run again with the same version step (nothing was pushed) |
| Play: "The caller does not have permission" or "Package not found" | The service account isn't invited, lacks the app permission, or Play hasn't caught up yet | Step 5.5; wait; run again with `rebuild` |
| Play: "Version code N has already been used" | That build number is already on Play | Run again with `rebuild` |
| Play: "Only releases with status draft may be created on draft app" | The app has never been published on that track | Upload this one build by hand in Play Console (the `.aab` is not kept by the run; build it with `./tool/release.ps1 -Rebuild`) |
| "Uploading Dart symbols" warns | The service account lacks the Crashlytics role | The release is fine. Fix the role (step 5.3); the symbols are in the GitHub release's `symbols-...zip` for a manual upload |
| The site shows a 404 | Pages isn't enabled, or the branch isn't allowed on the `github-pages` environment | Step 2 |
| The run failed **after** "Push the release commit and tag" | The version and tag now exist | Always `rebuild`: same name, next build number |

To switch the pipeline off: delete the `release` environment (its secrets go with it) and the deploy key.
