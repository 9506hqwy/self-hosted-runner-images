# Self Hosted Runner Images

This repository provide self hosted runner images.

## GitHub Actions

This runner run in container using Podman.

The container executed workflow once, then the container is stopped and is removed.
Systemd detects to stop container process, then systemd restarts container.
So, the runner is resigtered to GitHub per workflow executing.

![GitHub Actions Arch](./images/github-actions-runner-arch.png "GitHub Actions Arch")

### Build Container Image

Build container image that is self hosted runner.

Execute bellow command at *github* directory.

```sh
buildah build -t runner .
```

### Prepare

Copy systemd unit file.

```sh
cp systemd/system/* /etc/systemd/system/
```

Configure bellow environment value in *actions-runner\@.service*.

- `GITHUB_ORG_URL`
- `GITHUB_RUNNER_NAME`

Create secret for GitHub personal access token (PAT).
PAT need to have `repo`, `manage_runners:org`, or `manage_runners:enterprise` scope.

```sh
printf <PAT> | podman secret create github_token --replace -
```

Enable service.

```sh
systemctl daemon-reload
systemctl enable --now actions-runners.target
```

### Usage

Specify runner with optional labels at workflow.

```yaml
runs-on: self-hosted
```
