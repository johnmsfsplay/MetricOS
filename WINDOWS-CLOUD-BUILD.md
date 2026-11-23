# Build MetricOS from Windows 11 — no Ubuntu installation required

This uses GitHub Actions as a temporary cloud Linux build machine. It does **not** install Ubuntu, WSL, Docker, or Linux on your Windows PC. Your computer is only used to upload the source and download the resulting ISO.

## What you need

- A GitHub account.
- A web browser.
- The extracted `MetricOS-1.0` project folder.

## 1. Extract the ZIP

In Windows File Explorer, right-click `MetricOS-1.0-Full-Build-Kit.zip` and choose **Extract All**. Open the extracted `MetricOS-1.0` folder. You must see `build-iso.sh`, `metricos-spec.json`, `config`, `tests`, and `.github`.

## 2. Create a GitHub repository

1. Open https://github.com/new and sign in.
2. Repository name: `MetricOS`.
3. Choose **Public** if you want to use GitHub's published free/unlimited standard Actions allowance for public repositories. Public means the source code is visible to everyone. Choose Private if you do not want the source public; private repositories have plan-based Actions minutes/usage limits.
4. Do not add a README, `.gitignore`, or license on GitHub because this project already contains its own files.
5. Click **Create repository**.

## 3. Upload the project files (not the ZIP itself)

1. On the new empty repository page, choose **Add file → Upload files**.
2. In Windows File Explorer, open the extracted `MetricOS-1.0` folder.
3. Select **everything inside** that folder, including the `.github` folder (enable **View → Show → Hidden items** if `.github` is not visible).
4. Drag the selected files and folders onto GitHub's upload area. Keep the folder structure intact. `build-iso.sh` must be at the repository root, and the workflow must be at `.github/workflows/build-metricos.yml`.
5. Commit the upload to the `main` branch.

Do not upload only `MetricOS-1.0-Full-Build-Kit.zip`: GitHub Actions needs the extracted project files in the repository.

## 4. Start the cloud build

1. Open the repository's **Actions** tab.
2. If GitHub asks to enable Actions, enable them for this repository.
3. Select **Build MetricOS ISO** on the left.
4. Click **Run workflow**.
5. Leave **Include Google Chrome Stable** and **Include the Debian live installer** checked, then click the green **Run workflow** button.
6. Open the run that appears and watch the steps. The image build can take a while and uses internet downloads on GitHub's runner, not your PC.

The workflow first runs project tests, frees unused space on the disposable runner, builds the Debian Live image, checks the ISO9660/El Torito structure and SHA-256 checksum, then uploads the result.

## 5. Download the ISO

When the workflow is green:

1. Open that completed workflow run.
2. Scroll to **Artifacts** at the bottom.
3. Download `MetricOS-1.0-amd64-ISO`.
4. Extract the downloaded artifact ZIP. It contains:
   - `metricos-1.0-amd64.iso`
   - `metricos-1.0-amd64.iso.sha256`
   - `BUILD-INFO.txt`
   - `metricos-build.log`

The successful workflow verifies the checksum and ISO boot-catalog structure. It does **not** automatically prove the desktop works on your particular PC or replace a full QEMU/VirtualBox live-boot test. Test the ISO in a virtual machine before installing it on real hardware.

## Troubleshooting

- **No “Run workflow” button:** make sure the workflow file exists at `.github/workflows/build-metricos.yml` on the default `main` branch and Actions are enabled.
- **Workflow file not found:** you probably uploaded the ZIP itself or left the `MetricOS-1.0` folder nested one level too deep. `build-iso.sh` must be at the repository root.
- **Not enough disk space:** the workflow tries to reclaim space on the temporary runner and stops with a clear error if at least 27 GiB is not available. Retry later or use a larger hosted runner; it does not consume space on your Windows drive during compilation.
- **Google Chrome download fails:** rerun the workflow with Chrome unchecked. Firefox ESR remains included; Chrome can be installed after boot using the included installer shortcut.
- **Build fails:** open the failed run and inspect the first red step. If the build started, expand **Build ISO** and download/share `metricos-build.log` from the uploaded diagnostics if available. Never share an API key or personal access token.

## Privacy and cost

The repository contains the MetricOS source, not a Windows password or Gemini API key. Public repositories expose all source files publicly. Standard GitHub-hosted runner usage is published as free/unlimited for public repositories; GitHub's current runner availability, artifact retention, and account terms apply. A public source repo is not required if you are willing to use your private-repository Actions allowance or a larger runner.
