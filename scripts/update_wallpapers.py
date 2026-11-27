import urllib.request
import json
import ssl
import os
import sys

def main():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }

    target_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'data', 'wallpapers.json')
    
    wallpapers = []
    seen_urls = set()

    # Category mapper for shrines
    # 122: العتبة الحسينية المقدسة
    # 186: العتبة العلوية المقدسة
    # 188: العتبة الكاظمية المقدسة
    # 158: العتبة العسكرية المقدسة
    # 189: العتبة الرضوية المقدسة
    # 227: التل الزينبي
    # 130: الضريح المقدس
    # 131: مرقد الشهداء
    # 132: مرقد حبيب بن مظاهر
    # 160: بيت الله الحرام
    # 161: المسجد النبوي الشريف

    def map_category(item):
        cat_info = item.get('category') or {}
        cat_id = cat_info.get('id') if isinstance(cat_info, dict) else item.get('category_id')
        cat_name = cat_info.get('name', '') if isinstance(cat_info, dict) else ''
        title = item.get('title') or ''

        if cat_id == 186 or 'علوية' in cat_name or 'علي' in title or 'النجف' in title:
            return 'العتبة العلوية'
        elif cat_id == 158 or 'عسكرية' in cat_name or 'سامراء' in title or 'العسكريين' in title:
            return 'العتبة العسكرية'
        elif 'عباسية' in cat_name or 'العباس' in title or 'كفيل' in title:
            return 'العتبة العباسية'
        elif cat_id in [188, 189, 160, 161, 227, 131, 132, 133, 134] or 'مسجد' in cat_name or 'أماكن' in cat_name:
            return 'أماكن مقدسة'
        else:
            return 'العتبة الحسينية'

    # Step 1: Collect across pages from 1 to 20 (up to 1000 items)
    print("Collecting high-res photos from Imam Hussain shrine API (across 20 pages)...")
    for page in range(1, 21):
        try:
            url = f"https://pic.imamhussain.org/index.php/api/v2/photos?page={page}&limit=50"
            req = urllib.request.Request(url, headers=headers)
            resp = urllib.request.urlopen(req, timeout=12, context=ctx)
            data = json.loads(resp.read().decode('utf-8'))
            items = data.get('data', [])
            if not items:
                break
            
            for item in items:
                f = item.get('file') or item.get('image')
                if not f:
                    continue
                img_url = f"https://pic.imamhussain.org/photos/hd/{f}"
                thumb_url = f"https://pic.imamhussain.org/photos/{f}"

                if img_url in seen_urls:
                    continue
                seen_urls.add(img_url)

                cat = map_category(item)
                item_title = (item.get('title') or '').strip()
                if not item_title or item_title.isdigit():
                    item_title = f"{cat} - لقطة مباركة"

                tags = [cat, "عتبات", "مراقد", "خلفيات"]
                if "حسين" in item_title: tags.append("الإمام الحسين")
                if "عباس" in item_title: tags.append("أبو الفضل العباس")
                if "علي" in item_title: tags.append("أمير المؤمنين")
                if "قبة" in item_title: tags.append("القبة الشريفة")
                if "منارة" in item_title: tags.append("المنارة")
                if "ضريح" in item_title: tags.append("الضريح المقدس")

                wallpapers.append({
                    "id": f"hussain_{item.get('id')}",
                    "title": item_title,
                    "category": cat,
                    "imageUrl": img_url,
                    "thumbnailUrl": thumb_url,
                    "sourceName": "العتبة الحسينية المقدسة",
                    "sourceUrl": "https://pic.imamhussain.org",
                    "tags": tags,
                    "views": item.get('views', 150),
                    "likes": item.get('likes', 85)
                })
        except Exception as e:
            print(f"Notice on page {page}: {e}")

    # Fetch latest curated wallpapers from official repository
    repo_url = "https://raw.githubusercontent.com/moshraheem-sudo/Islamic-Shrines-Wallpapers/main/data/wallpapers.json"
    try:
        print("Syncing with official Islamic-Shrines-Wallpapers repository...")
        req = urllib.request.Request(repo_url, headers=headers)
        resp = urllib.request.urlopen(req, timeout=15, context=ctx)
        repo_data = json.loads(resp.read().decode('utf-8'))
        repo_items = repo_data if isinstance(repo_data, list) else repo_data.get('items', [])
        if repo_items and len(repo_items) > 100:
            print(f"Loaded {len(repo_items)} verified wallpapers from official repository.")
            wallpapers = repo_items
    except Exception as e:
        print(f"Could not fetch official repository, using collected items: {e}")

    print(f"Total wallpapers assembled: {len(wallpapers)}")

    with open(target_file, 'w', encoding='utf-8') as f:
        json.dump(wallpapers, f, ensure_ascii=False, indent=2)

    print(f"Successfully saved {len(wallpapers)} wallpapers to {target_file}")

if __name__ == '__main__':
    main()
