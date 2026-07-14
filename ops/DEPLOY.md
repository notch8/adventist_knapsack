# Deploy runbook

The same deploy path for staging and production: `bin/deploy <environment> [git_ref] [image_tag]`.
Both environments run the same `docker-compose.production.yml`-shaped topology
(healthchecks, `restart: unless-stopped`, root user, host bind mounts)

Read this whole file before running anything on staging for the first time -
step 2 (disk cleanup) is a hard blocker, not optional.

## One-time setup: secrets in 1Password

Secrets no longer live only on one laptop or as hand-edits on a box. They're
documents in the `ADVENTIST` 1Password vault, same pattern already used for
`id_rsa` / `ghcr_token` / `cloudflare.ini` (see `provision/bin/run`).

1. Make sure you're signed in: `eval $(op signin)`
2. If `.env.production` on this machine already has real production values
   (it does, as of this writing), upload it once:
   ```bash
   op document create .env.production --title ENV_PRODUCTION_SECRETS --vault "ADVENTIST"
   ```
3. Fill in the remaining `TODO_STAGING_*` placeholders in `.env.staging`
   (see "Staging secrets - status" below), then upload it:
   ```bash
   op document create .env.staging --title ENV_STAGING_SECRETS --vault "ADVENTIST"
   ```
4. From here on, anyone with vault access can regenerate either file locally:
   ```bash
   ./provision/bin/fetch-secrets staging      # writes .env.staging
   ./provision/bin/fetch-secrets production   # writes .env.production
   ```
   `bin/push-env <environment>` (run from your laptop) calls this
   automatically, then copies the result onto the server - the server itself
   has no `op` access, so `bin/deploy` (run on the server) only checks the
   files are present rather than fetching them. See "Deploying" below.
5. After rotating any secret, push the update back: `op document edit ENV_STAGING_SECRETS .env.staging` (or `edit` the production title).

### Staging secrets - status

`.env.staging` has generated-and-ready internal secrets (DB/Redis/Solr/Rails -
these only need to be consistent between the app and its own backing services,
so freshly generated values are correct and safe).

Resolved (reusing production's IAM key pairs, per-bucket per your call):
- `REPOSITORY_S3_*` - `samvera-original-files-staging` bucket created (private, AES256, full public-access-block, matching production's `samvera-original-files`). Originally and incorrectly noted here as already existing - it didn't; confirmed via `Aws::S3::Errors::NoSuchBucket` on a real ingest attempt, then verified directly against AWS before creating it.
- `FCREPO_AWS_KEY` / `FCREPO_AWS_SECRET` / `FCREPO_S3_BUCKET` - created `samvera-fcrepo-staging`, mirroring `samvera-fcrepo`'s encryption/public-access-block settings.

Deferred, intentionally left out of `.env.staging` entirely (not set to a
placeholder or to production's real values):
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_S3_BUCKET` (the "preprocessed" bucket). This one isn't a plain bucket - it's fed by a separate Serverless Framework app ("space-stone") with Lambda functions that process what lands there, and that app's source isn't in this repo. A "space-stone-dev" stage exists but is in the wrong region (us-west-2, this app is us-east-1). Omitted rather than pointed at production's real bucket/key: that would work, but silently feed staging test data into production's live pipeline - worse than the aux-worker failing loudly on missing credentials. Resolve by deploying a proper `--stage staging` of the space-stone app (needs access to that repo), or explicitly decide to accept cross-region reuse of `space-stone-dev`.

Still `TODO_STAGING_*`, needs a real decision + credential from you:
- `GOOGLE_ACCOUNT_JSON` - only needed if staging should have working Google Analytics/Sheets integration; confirm whether it does.
- `SENTRY_DSN` - ideally a separate Sentry project/environment so staging noise doesn't pollute production alerts.
- `SMTP_PASSWORD` - only needed if staging should send real email; confirm whether it should (probably not, to avoid staging tests emailing real users).

## Staging: one-time storage prep (do this before the first deploy)

Staging's `/store/keep` volume is a single 131G filesystem, already **97% full
(126G used, ~4G free)** - there's no dedicated `/store/tmp`, `db_data`,
`fcrepo_data`, `solr-data`, `redis_data` volumes like production has. This is
fine functionally (Docker bind mounts don't care whether a path is its own
filesystem or a plain directory), but the disk needs headroom first.

### 1. Clear the ~120G of orphaned files from the old staging rsync

Resolved (2026-07): `hyrax-webapp/storage/files` is confirmed to be staging's
**live** local-disk fallback path - Hyrax writes here directly when S3 storage
config is missing, confirmed by a real upload landing at
`.../storage/files/6f/8e/6a/.../strasbourg_balcony.jpg`. That fallback stops
happening once staging redeploys with the new `.env.staging`
(`REPOSITORY_S3_BUCKET=samvera-original-files-staging` is now wired up).

The bulk of the ~120G (everything dated 2025-12-14/15) is leftover from an old
rsync into the previous staging environment, whose Postgres DB and Solr index
were never reconciled against it - so none of it is referenced by anything
Hyrax currently knows about. Worth one quick, free sanity check before
clearing, since it fully confirms orphan status rather than just assuming it:

```bash
ssh <staging-host>
# staging's Solr should already be known-empty (per the original notes: no
# tenant has any real works) - confirm that's still true
curl -s "http://<solr-admin-user>:<solr-admin-password>@localhost:8983/solr/<staging-collection>/select?q=*:*&rows=0" | grep numFound
```
If Solr genuinely has ~0 documents, there's nothing in the current app that
could reference these files, and the December content is safe to clear. This
path is also where staging's local-disk fallback is actively writing (a real
test upload landed there on 2026-07-07) - delete by exclusion rather than a
blanket wipe, so anything genuinely current survives:
```bash
ROOT='/store/keep/adventist_knapsack/hyrax-webapp/storage/files'
KEEP='/store/keep/adventist_knapsack/hyrax-webapp/storage/files/6f/8e/6a/6f8e6af8e69943b5ba2bb7a7aa3b7520/strasbourg_balcony.jpg'

# sanity check first - should report exactly one fewer file than the total
find "$ROOT" -type f | wc -l
find "$ROOT" -type f ! -path "$KEEP" | wc -l

sudo find "$ROOT" -type f ! -path "$KEEP" -delete
sudo find "$ROOT" -depth -type d -empty -delete   # cascades up, leaves $KEEP's directory chain intact
df -h /store/keep   # confirm real headroom
```

### 2. Create the directories `docker-compose.staging.yml` expects

```bash
sudo mkdir -p \
  /store/keep/derivatives \
  /store/keep/branding \
  /store/keep/exports \
  /store/keep/imports \
  /store/keep/public-system \
  /store/keep/public-uploads \
  /store/keep/tmp/network-files \
  /store/keep/tmp/public-assets \
  /store/keep/tmp/uploads \
  /store/keep/tmp/ruby-tmp-dir \
  /store/keep/zoo_data \
  /store/keep/zoo_datalog \
  /store/keep/solr-data \
  /store/keep/fcrepo_data \
  /store/keep/db_data/pg14 \
  /store/keep/db_data/dumps \
  /store/keep/redis_data \
  /cache
```

### 3. Seed host-mounted paths that shadow content baked into the image

Docker **bind mounts** (host directory -> container path) don't get the
"copy the image's existing content into the volume on first use" treatment
that **named volumes** get - that's named-volume-only behavior. Two paths in
this compose file mount over locations the image ships pre-populated:
`solr`'s `/var/solr` (ships a default `security.json`) and the app's
`hyrax-webapp/public/assets` (precompiled, fingerprinted Sprockets assets
baked in at image build time). On a genuinely fresh host directory, both are
silently hidden, causing Solr's healthcheck to fail auth and the app to serve
completely unstyled pages (asset 404s). Confirmed on staging's first real
deploy - do this *before* first bringing the stack up on any fresh
environment:

There's a third, related gap that isn't a bind-mount issue but the same
underlying cause (production accumulated one-off manual setup over time that
was never captured anywhere): `fcrepo` connects to its own Postgres role/database
(separate from the main Hyku one, `-Dfcrepo.postgresql.username=fcrepo`), but
the official `postgres` image's first-boot init only creates the ONE
user/database given via `POSTGRES_USER`/`POSTGRES_DB`. On a genuinely fresh
`db` volume, the `fcrepo` role never exists, and fcrepo fails with
`FATAL: password authentication failed for user "fcrepo"` - which surfaces to
the app as `Ldp::HttpError (STATUS: 503)`, specifically when creating anything
that needs a Fedora resource (a new tenant's default Admin Set, for example -
confirmed via this exact failure on staging's first tenant-creation attempt).
Fix once per fresh `db` volume:
```bash
FCREPO_PW=$(grep '^FCREPO_DB_PASSWORD=' .env.staging | cut -d= -f2- | tr -d "'")
cat > /tmp/create_fcrepo_role.sql <<SQL
CREATE ROLE fcrepo WITH LOGIN PASSWORD '$FCREPO_PW';
CREATE DATABASE fcrepo OWNER fcrepo;
SQL
docker cp /tmp/create_fcrepo_role.sql adventist_knapsack-db-1:/tmp/create_fcrepo_role.sql
docker exec adventist_knapsack-db-1 psql -U hyku-staging-hyrax -d hyku-staging-hyrax -f /tmp/create_fcrepo_role.sql
docker exec adventist_knapsack-db-1 rm -f /tmp/create_fcrepo_role.sql
rm -f /tmp/create_fcrepo_role.sql
docker restart adventist_knapsack-fcrepo-1
```
(swap `.env.staging`/`hyku-staging-hyrax` for production's equivalents)

```bash
IMAGE=ghcr.io/notch8/adventist_knapsack/web:<tag you're deploying>

# Solr's security.json (path differs if you're not on staging's single-volume layout)
sudo docker create --name _seed ghcr.io/samvera/hyku/solr:latest
sudo docker cp _seed:/var/solr/data/security.json /store/keep/solr-data/data/security.json
sudo docker rm _seed
sudo chown -R 8983:8983 /store/keep/solr-data

# Precompiled assets - staging's path shown; production uses /store/tmp/public-assets
sudo docker create --name _seed "$IMAGE"
sudo docker cp _seed:/app/samvera/hyrax-webapp/public/assets/. /store/keep/tmp/public-assets/
sudo docker rm _seed
sudo chown -R 1001:101 /store/keep/tmp/public-assets   # app:app inside the image (Dockerfile's COPY --chown)
```

Note the ownership fixes use `sudo chown` directly on the host with the raw
UID/GID (1001:101, from the Dockerfile's `COPY --chown=1001:101`) rather than
`docker run ... chown` as the container's own `app` user - that user can't
chown files it doesn't already own (`Operation not permitted`), since it's
unprivileged inside the image.

**If you're doing this after the stack is already running** (as opposed to
before first boot, e.g. while debugging an already-deployed fresh
environment): seeding the assets isn't enough on its own. Rails loads the
Sprockets manifest once at boot and caches it in memory - it has no way to
notice files that appeared on disk afterward. The symptom is confusing: the
page loads fine (200), but `stylesheet_link_tag`/`javascript_include_tag`
silently fall back to non-fingerprinted legacy paths (`/stylesheets/application.css`,
`/javascripts/application.js`, both 404) instead of raising an error. Restart
`web` (and `worker`, cheap and harmless) after seeding to force Rails to
re-read the now-present manifest:
```bash
docker restart adventist_knapsack-web-1 adventist_knapsack-worker-1
```

## Deploying

Two machines are involved, since the server itself has no 1Password access:

**1. On your laptop** (needs `op` signed in - Touch ID/biometric prompts are
fine, `eval $(op signin)` isn't required), push current secrets to the target
server:
```bash
bin/push-env staging      # or: bin/push-env production
```
This uses direct VPN access as **your own personal account** (default SSH
identity/agent, no shared key) straight to `192.168.147.200`/`.100` -
**confirmed working 2026-07-07** for personal accounts with sudo, docker
group, and (since the `storage-perms` fix) write access to
`/store/keep/adventist_knapsack` via the `adventist-data` group on both boxes.
No jump box needed for this part, and no dependency on the shared
`adlquantum6269` account or its `DEPLOY_ID_RSA` key - that account still
exists and still works, but nothing here relies on it anymore, which is one
less shared credential to worry about (see the offboarding notes below).
Needs your local username to match your server username and VPN connected.
Before overwriting anything, it backs up whatever `.env.common`/
`.env.<environment>` are currently on the server to `<file>.bak-<timestamp>`
right alongside them (gitignored, same as the originals) - if a push turns
out to be wrong, the previous version is sitting right there to restore.
Falls back to printing manual jump-box instructions (`ssh 21jumpbox`, password
from 1Password, `scp` onward to `adventist-staging`/`adventist-prod`) if
direct access ever stops working for you.

**2. On the server** (SSH in via VPN or the jump box - see the
[playbook's access instructions](https://github.com/notch8/playbook/blob/main/maint-clients/adventist.md)),
same command shape for both environments, run from the repo root
(`/store/keep/adventist_knapsack`). **Run this as yourself (e.g. `max`), not
as `root`** - running it as root means `git checkout`/`git pull` rewrite
`.env.common` (a tracked file) with root's default permissions, silently
un-doing the group-writable state `bin/push-env` needs for the next person's
push. If that happens: `sudo chmod 664 .env.common` fixes it.
```bash
# staging, latest main
bin/deploy staging

# staging, a specific branch/tag/image
bin/deploy staging my-feature-branch my-feature-branch

# production - only after staging has proven out (see checklist below)
bin/deploy production

# rollback production to the known-good pre-this-work state
bin/deploy production v1.0.0 v1.0.0
```

What it does (see `bin/deploy` for the exact commands): checks `.env.common`
and `.env.<environment>` are present (fails with a pointer to `bin/push-env`
if not), stashes (not discards) any local drift in either the repo or the
submodule so it can't silently block or get clobbered by the pull, checks out
the requested git ref, pulls images, runs `docker compose up -d`, and polls
`/up` until it's healthy. Migrations are not a separate step - the existing
`initialize_app` service (`bin/db-migrate-seed.sh`) already runs
`rails db:migrate` before `web`/`worker` are allowed to start. If a stash ever
gets created, `git stash list` (and the same in `hyrax-webapp/`) shows it -
nothing is silently lost.

`db/schema.rb` in the submodule drifting after (almost) every deploy is
expected, not a surprise - `db:migrate` regenerates it to match whatever ran,
and that regenerated version isn't always what's committed upstream. The
auto-stash handles it every time; if `git stash list` in `hyrax-webapp/`
grows long over many deploys, that's just this - safe to `git stash drop`
old entries once you've confirmed nothing else is in them, since the file
itself gets regenerated fresh by the next migrate anyway.

`git safe.directory` for the repo and submodule (needed because the directory
is `root:adventist-data`, not owned by whoever's SSH'd in - without it git
refuses to run at all) is set up once, system-wide, by `provision/site.yml`
(the `git-safe-directory` tag) - a host-provisioning concern, not something
`bin/deploy` handles per-run.

## Verification checklist before trusting a staging deploy

Run through this on staging before ever pointing `bin/deploy production` at a
new ref:

- [ ] `bin/deploy staging` completes and prints a passing healthcheck
- [ ] `set -a && source .env.common && source .env.staging && set +a && docker-compose -f docker-compose.staging.yml logs initialize_app` shows migrations ran (or "all migrations have been run" with nothing pending)
- [ ] `curl -fsS https://s2.adventistdigitallibrary.org/up` succeeds from outside the box, not just `localhost:3000`
- [ ] `docker restart <web container>` and confirm it comes back on its own (`restart: unless-stopped` actually behaves)
- [ ] Uploading a test file lands in the staging S3 bucket, not local disk and not production's bucket
- [ ] `df -h /store/keep` still has headroom after the deploy

## Credential hygiene / offboarding

When someone with server or 1Password access leaves:

1. Remove them from `ssh_users` in `provision/vars/main.yml` (stops future
   playbook runs from re-granting their key) - this alone does **not** revoke
   anything already live.
2. Lock their account on both boxes: `sudo usermod -L -s /usr/sbin/nologin <user>`,
   disable their `authorized_keys`, remove them from the `sudo`/`docker`
   groups. Prefer locking over `userdel` first - reversible if something turns
   out to still reference the account.
3. Check their `ADVENTIST` 1Password vault membership and GitHub org/repo
   access - these control whether they can get *fresh* copies of anything
   going forward, which matters more than what they already have.
4. Rotate anything they had a static, already-downloaded copy of, since
   removing vault/GitHub access doesn't invalidate a copy someone already
   has - `DEPLOY_ID_RSA`, `ANSIBLE_BECOME_PASSWORD` (this is also almost
   certainly the jump-box's password-auth prompt for `adlquantum6269` -
   confirm they're the same value, not two independently-drifted ones),
   `GHCR_TOKEN`, `CLOUDFLARE_INI`, and any AWS IAM keys they had console or
   local access to (the `adventist` AWS profile's access keys are reused
   across `.env.production` and `.env.staging` - see above). Add-new-before-
   removing-old for anything that would otherwise lock out current access.

The shared `adlquantum6269` + `DEPLOY_ID_RSA` account still exists and still
works for the jump-box fallback, but as of the personal-account switch above,
nothing in this repo's tooling depends on it day to day - one less shared
credential in the loop.

## Known, deliberately out-of-scope items

- **GitHub Actions automation** - deferred until SSH/server access is easier to arrange and this manual path has been proven out on staging and production.
- **Root-owned files on staging** - caused by `user: root` in the compose file itself, same as production; not a regression, not fixed here.
- **Matching production's dedicated per-service volumes on staging** - would mean requesting new disks from the hosting provider. Not needed for a trustworthy staging; revisit only if the single-volume layout becomes a real problem.
- **Rotating `REDIS_PASSWORD`/`SOLR_ADMIN_PASSWORD` on production** - both are weak/example values (`mysecret`, `SolrRocks`) today. Worth fixing, but as a deliberate, coordinated change during a maintenance window, not as a side effect of this work.
