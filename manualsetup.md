# Manual setup

Steps that `setup.sh` cannot do, and why. Everything here needs either a secret that
must not live in this repo, or a browser on a managed device.

Run `bootstrap.sh` (or `setup.sh` on an existing clone) first — these steps assume the
tooling it installs is already present.

---

## Azure DevOps access

Needed for any repo whose `origin` points at `dev.azure.com` — currently `grcmap`.

### Why this is manual

A Conditional Access policy requires a managed, compliant device. Windows proves that
with a Primary Refresh Token held in the TPM and brokered by WAM. WSL is a separate OS
instance with no device identity and no access to that PRT, so it cannot satisfy the
check — **both** `az login` in a browser and `az login --use-device-code` are refused.
Git Credential Manager fails for the same reason; its OAuth path is foreclosed by the
same policy.

A Personal Access Token sidesteps this, because it authenticates as a credential
registered against the account rather than proving what machine is asking. The cost is
that PATs expire and cannot be scripted into this repo.

### 1. Create the PAT

In a browser **on Windows**, signed in as the DevOps admin account:

`https://dev.azure.com/SduLandingZones/_usersSettings/tokens` → New Token

Scopes — the minimum that covers the workflow:

| Scope | Access | Needed for |
|---|---|---|
| Code | Read & write | clone, push, create PRs |
| Work Items | Read & write | `az boards` |

Set the expiry to the longest the org policy allows. Copy the token now; it cannot be
read back afterwards.

### 2. Create the machine-local identity file

Commits to DevOps remotes are authored by the admin account. `configs/gitconfig` has
the `includeIf` that activates this automatically — only the file itself is manual,
since it names an identity rather than a setting:

```bash
git config --file ~/.gitconfig-devops user.name  "Simon Kamber"
git config --file ~/.gitconfig-devops user.email "ca-kamber@sdunet.dk"
```

### 3. Give git the PAT

`configs/gitconfig` scopes git's built-in `store` helper to `dev.azure.com`. It has
nothing cached on a new machine, so git falls through to prompting. The remote URL
carries the org as userinfo (`https://SduLandingZones@dev.azure.com/...`), so only the
password is asked for.

Run this in a **real terminal** — git needs `/dev/tty` to prompt, and fails with
`could not read Password ... No such device or address` if it cannot get one:

```bash
cd ~/workspace/devops/ca-kamber/grcmap
git ls-remote origin HEAD
```

Paste the PAT at the `Password:` prompt. Do not pass it as a command argument — it
would land in shell history. It is written to `~/.git-credentials`, mode 600.

A 401 here means the PAT is missing **Code (read)**.

### 4. Give `az` the PAT

`az devops` uses the REST API and does not read git's credential store, so it needs its
own copy. It reads the token from stdin:

```bash
az devops login
```

**Do not pass `--organization`.** It scopes the stored PAT to one exact organization
URL. Commands run inside a repo auto-detect the organization from the git remote, and
that remote carries the org as userinfo (`https://SduLandingZones@dev.azure.com/...`),
so the detected string does not match a URL registered without it. Every command then
fails with "you need to run the login command", which reads like the login never
happened rather than like a lookup miss. With no organization, the PAT is stored as a
default that any lookup finds.

The same userinfo is why the `includeIf` in `configs/gitconfig` needs a
`https://*@dev.azure.com/**` pattern. Suspect it first whenever something DevOps-shaped
fails to match.

Stored under `~/.azure`. No `az login` is required — and would fail anyway, per above.

### 5. Verify

```bash
cd ~/workspace/devops/ca-kamber/grcmap
git config user.email                        # ca-kamber@sdunet.dk — the includeIf fired
git ls-remote origin HEAD                    # a SHA, with no prompt this time
az repos pr list --status active -o table    # the CLI half works
```

If `user.email` shows the personal address, the `includeIf` did not match the remote
URL. `git config --show-origin user.email` names the file that supplied it.

The `az repos` call working also proves org/project auto-detection from the git remote,
which is what allows omitting `--organization` and `--project` everywhere else.

### Daily use

```bash
git checkout -b feature/short-thing
git push -u origin feature/short-thing
az repos pr create --title "Short thing" --draft
az repos pr list --status active -o table
az repos pr update --id <n> --draft false
```

`--draft` opens the PR without notifying reviewers, leaving room for follow-up commits
before it reads as a real request.

### When the PAT expires

Both git and the CLI fail at once, with a 401 rather than anything saying "expired".
Repeat steps 1, 3 and 4 — step 2 persists. Clear the stale git entry first:

```bash
git credential reject <<<$'protocol=https\nhost=dev.azure.com\n'
```

Neither `~/.git-credentials` nor `~/.azure` is in this repo, so a rebuild always costs
one browser trip plus two pastes.
