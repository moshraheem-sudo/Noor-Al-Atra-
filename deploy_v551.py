import os
import sys
import json
import subprocess
import urllib.request
import urllib.error

def get_github_token():
    p = subprocess.Popen(['git', 'credential', 'fill'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, err = p.communicate('protocol=https\nhost=github.com\n\n')
    for line in out.splitlines():
        if line.startswith('password='):
            return line.split('=', 1)[1].strip()
    raise RuntimeError("Could not retrieve GitHub token")

def main():
    token = get_github_token()
    repo = "moshraheem-sudo/Noor-Al-Atra-"
    remote_url = f"https://moshraheem-sudo:{token}@github.com/moshraheem-sudo/Noor-Al-Atra-.git"
    
    # 1. Commit changes
    print("Step 1: Committing git changes...")
    subprocess.run(['git', 'add', '-A'], check=True)
    subprocess.run(['git', 'reset', 'HEAD', 'Noor_Al-Atra_*.apk'], check=False)
    subprocess.run(['git', 'commit', '-m', 'feat: release v5.51.0 - fix verse share centering and swiping, clean audio title, style recitation card, add salaty app download with version tracking'], check=False)
    
    # 2. Push to GitHub
    print("Step 2: Pushing to GitHub main...")
    push_res = subprocess.run(['git', 'push', remote_url, 'main'], capture_output=True, text=True)
    print("Push stdout:", push_res.stdout)
    if push_res.returncode != 0:
        print("Push stderr:", push_res.stderr)
        # try force if rejected
        subprocess.run(['git', 'push', remote_url, 'main', '--force'], check=True)

    tag_name = "5.51.0"
    release_name = "تطبيق نور العترة v5.51.0"
    release_body = (
        "### التحديث v5.51.0 لتطبيق نور العترة\n\n"
        "**أبرز الإصلاحات والميزات الجديدة:**\n"
        "- **توسيط عنوان نافذة مشاركة الآية كصورة**: توسيط دقيق ومتناسق في أعلى النافذة.\n"
        "- **إصلاح تبديل الألوان في نافذة المشاركة**: منع الإغلاق المفاجئ عند التمرير الأفقي بين الأنماط والأبعاد.\n"
        "- **نافذة الصوتيات**: إزالة الكلمات الزائدة من شريط العنوان وتثبيت اسم «صوتيات» منعاً لاختفائه أو تداخله.\n"
        "- **تلاوة السورة واختيار القارئ**: معالجة البطاقة لتتناسق بالكامل مع الوضع الفاتح وتوضيح النصوص دون سواد غير ملائم.\n"
        "- **تطبيق صوت القرآن الكريم**: عرض رقم الإصدار المتوفر دائماً مع التحميل المباشر وحساب الحجم (MB).\n"
        "- **إضافة تطبيق صلاتي**: إتاحة تحميل تطبيق صلاتي (مواقيت الصلاة والأذان) مع عرض رقم إصداره المتوفر دائماً."
    )

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "Antigravity-Release-Publisher",
        "X-GitHub-Api-Version": "2022-11-28"
    }

    print("\nStep 3: Creating or updating release 5.51.0...")
    req = urllib.request.Request(f"https://api.github.com/repos/{repo}/releases/tags/{tag_name}", headers=headers)
    release = None
    try:
        with urllib.request.urlopen(req) as resp:
            release = json.loads(resp.read().decode('utf-8'))
            print("Release exists with ID:", release['id'])
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print("Creating new release...")
        else:
            print("Error checking release:", e)
            sys.exit(1)

    if not release:
        payload = json.dumps({
            "tag_name": tag_name,
            "target_commitish": "main",
            "name": release_name,
            "body": release_body,
            "draft": False,
            "prerelease": False
        }).encode('utf-8')
        
        create_req = urllib.request.Request(
            f"https://api.github.com/repos/{repo}/releases",
            data=payload,
            headers={**headers, "Content-Type": "application/json"}
        )
        try:
            with urllib.request.urlopen(create_req) as resp:
                release = json.loads(resp.read().decode('utf-8'))
                print("Created release successfully! ID:", release['id'])
        except urllib.error.HTTPError as e:
            print("Failed to create release:", e.code, e.read().decode('utf-8'))
            sys.exit(1)

    upload_url_template = release.get("upload_url", "")
    upload_url = upload_url_template.split("{")[0]

    apk_source = os.path.abspath("build/app/outputs/flutter-apk/app-release.apk")
    apk_target = os.path.abspath("Noor_Al-Atra_5.51.0.apk")
    
    if os.path.exists(apk_source):
        import shutil
        shutil.copy2(apk_source, apk_target)
        print("Copied APK to", apk_target)

    file_size = os.path.getsize(apk_target)
    file_name = "Noor_Al-Atra_5.51.0.apk"
    print(f"\nStep 4: Uploading APK ({file_size / (1024*1024):.2f} MB)...")

    # Remove existing asset if any
    for asset in release.get("assets", []):
        if asset["name"] == file_name:
            print(f"Deleting existing asset ID: {asset['id']}...")
            del_req = urllib.request.Request(
                f"https://api.github.com/repos/{repo}/releases/assets/{asset['id']}",
                headers=headers,
                method="DELETE"
            )
            try:
                with urllib.request.urlopen(del_req) as dresp:
                    print("Deleted.")
            except Exception as ex:
                print("Delete asset error:", ex)

    asset_upload_url = f"{upload_url}?name={file_name}"
    with open(apk_target, "rb") as f:
        apk_data = f.read()

    upload_req = urllib.request.Request(
        asset_upload_url,
        data=apk_data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/vnd.android.package-archive",
            "User-Agent": "Antigravity-Release-Publisher",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Length": str(len(apk_data))
        }
    )

    try:
        with urllib.request.urlopen(upload_req) as resp:
            asset_info = json.loads(resp.read().decode('utf-8'))
            print("Successfully uploaded asset!")
            print("Download URL:", asset_info.get("browser_download_url"))
            print("Release URL:", release.get("html_url"))
    except urllib.error.HTTPError as e:
        print("Upload failed:", e.code, e.read().decode('utf-8'))
        sys.exit(1)

    print("\nSUCCESS: All done!")

if __name__ == "__main__":
    main()
