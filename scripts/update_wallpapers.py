import urllib.request
import re
import ssl
import json
import os
import sys

def main():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'ar,en-US;q=0.7,en;q=0.3'
    }

    target_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'data', 'wallpapers.json')
    
    existing = []
    if os.path.exists(target_file):
        try:
            with open(target_file, 'r', encoding='utf-8') as f:
                existing = json.load(f)
        except Exception as e:
            print("Notice reading existing:", e)

    wallpapers = []
    seen_urls = set()

    # 1. Imam Hussain Holy Shrine (API)
    try:
        req = urllib.request.Request('https://pic.imamhussain.org/index.php/api/v2/photos?page=1&limit=35', headers=headers)
        data = json.loads(urllib.request.urlopen(req, timeout=15, context=ctx).read().decode('utf-8'))
        for item in data.get('data', []):
            f = item.get('file') or item.get('image')
            if f:
                cat_name = (item.get('category') or {}).get('name', '')
                category = "العتبة الحسينية"
                if "أماكن" in cat_name or "مقدسة" in cat_name or item.get('category_id') == 123:
                    category = "أماكن مقدسة"
                
                img_url = f"https://pic.imamhussain.org/photos/hd/{f}"
                thumb_url = f"https://pic.imamhussain.org/photos/{f}"
                if img_url not in seen_urls:
                    seen_urls.add(img_url)
                    wallpapers.append({
                        "id": f"hussain_{item['id']}",
                        "title": item.get('title') or "مرقد سيد الشهداء الإمام الحسين (ع)",
                        "category": category,
                        "imageUrl": img_url,
                        "thumbnailUrl": thumb_url,
                        "sourceName": "معرض العتبة الحسينية المقدسة",
                        "sourceUrl": "https://pic.imamhussain.org/",
                        "tags": ["كربلاء المقدسة", "الإمام الحسين", "العتبة الحسينية"],
                        "isFeatured": len(wallpapers) < 2
                    })
    except Exception as e:
        print("Error fetching imamhussain:", e)

    # 2. Holy Places Category (Imam Hussain API)
    try:
        req = urllib.request.Request('https://pic.imamhussain.org/index.php/api/v2/photos?page=1&limit=25&category=123', headers=headers)
        data = json.loads(urllib.request.urlopen(req, timeout=15, context=ctx).read().decode('utf-8'))
        for item in data.get('data', []):
            f = item.get('file') or item.get('image')
            if f:
                img_url = f"https://pic.imamhussain.org/photos/hd/{f}"
                thumb_url = f"https://pic.imamhussain.org/photos/{f}"
                if img_url not in seen_urls:
                    seen_urls.add(img_url)
                    wallpapers.append({
                        "id": f"holy_{item['id']}",
                        "title": item.get('title') or "مقام ومرقد مقدس",
                        "category": "أماكن مقدسة",
                        "imageUrl": img_url,
                        "thumbnailUrl": thumb_url,
                        "sourceName": "معرض الأماكن المقدسة",
                        "sourceUrl": "https://pic.imamhussain.org/category/holyplaces",
                        "tags": ["أماكن مقدسة", "العتبات المقدسة", "مراقد أهل البيت"],
                        "isFeatured": False
                    })
    except Exception as e:
        print("Error fetching holy places:", e)

    # 3. Al-Kafeel (Al-Abbas Holy Shrine)
    try:
        req = urllib.request.Request('https://pic.alkafeel.net/tag/14?lang=ar', headers=headers)
        html = urllib.request.urlopen(req, timeout=15, context=ctx).read().decode('utf-8', errors='ignore')
        matches = re.findall(r'(https://main\.pictures\.alkafeel\.net/storage/photos/([^\s"\'<>]+\.(?:jpeg|jpg|png)))', html)
        for i, (full_url, filename) in enumerate(matches[:20]):
            if full_url not in seen_urls and '/avatars/' not in full_url:
                seen_urls.add(full_url)
                wallpapers.append({
                    "id": f"alkafeel_{len(wallpapers)+1}",
                    "title": "مرقد أبي الفضل العباس (عليه السلام) - كربلاء المقدسة",
                    "category": "العتبة العباسية",
                    "imageUrl": full_url,
                    "thumbnailUrl": full_url.replace('/storage/photos/', '/storage/photos/235/'),
                    "sourceName": "شبكة الكفيل العالمية",
                    "sourceUrl": "https://pic.alkafeel.net/tag/14?lang=ar",
                    "tags": ["كربلاء المقدسة", "أبو الفضل العباس", "الكفيل", "العتبة العباسية"],
                    "isFeatured": (i == 0)
                })
    except Exception as e:
        print("Error fetching alkafeel:", e)

    # 4. Imam Ali (Najaf)
    try:
        req = urllib.request.Request('https://media.imamali.net/?id=322', headers=headers)
        html = urllib.request.urlopen(req, timeout=15, context=ctx).read().decode('utf-8', errors='ignore')
        matches = re.findall(r'(https://imamali\.net/files/[^\s"\'<>]+\.(?:png|jpg|jpeg))', html)
        ali_titles = [
            "إيوان الذهب وضريح أمير المؤمنين (ع)",
            "القبة الذهبية لحرم الإمام علي (ع)",
            "الصحن الحيدري الشريف في النجف الأشرف",
            "مآذن ومنارات مرقد الإمام علي (ع)",
            "ضريح أمير المؤمنين علي بن أبي طالب (ع)",
            "ساعة العتبة العلوية المقدسة الشريفة",
            "باب القبلة لمرقد الإمام علي (ع)",
            "جامع الروضة الحيدرية المطهرة"
        ]
        for i, full_url in enumerate(matches[:15]):
            if full_url not in seen_urls:
                seen_urls.add(full_url)
                wallpapers.append({
                    "id": f"imamali_{len(wallpapers)+1}",
                    "title": ali_titles[i % len(ali_titles)],
                    "category": "العتبة العلوية",
                    "imageUrl": full_url,
                    "thumbnailUrl": full_url,
                    "sourceName": "شبكة الإمام علي (ع)",
                    "sourceUrl": "https://media.imamali.net/?id=322",
                    "tags": ["النجف الأشرف", "أمير المؤمنين", "العتبة العلوية"],
                    "isFeatured": (i == 0)
                })
    except Exception as e:
        print("Error fetching imamali:", e)

    # 5. Al-Askarian (Samarra)
    askarian_items = [
        ("https://alaskarian.net/storage/GZf0VF6cgXWBDKJV_1781708277.webp", "القبة المذهبة لحرم الإمامين العسكريين (ع) في سامراء"),
        ("https://alaskarian.net/storage/GZf0VF6cgXWBDKJV_1781708277.webp", "سرداب الغيبة الشريف والعتبة العسكرية المطهرة")
    ]
    for u, t in askarian_items:
        if u not in seen_urls:
            seen_urls.add(u)
            wallpapers.append({
                "id": f"askarian_{len(wallpapers)+1}",
                "title": t,
                "category": "العتبة العسكرية",
                "imageUrl": u,
                "thumbnailUrl": u,
                "sourceName": "العتبة العسكرية المقدسة",
                "sourceUrl": "https://alaskarian.net/gallery?id=1",
                "tags": ["سامراء المقدسة", "الإمامين العسكريين", "سرداب الغيبة"],
                "isFeatured": True
            })

    # Preserve any older existing items that weren't scraped this turn
    for ex in existing:
        if ex.get('imageUrl') and ex['imageUrl'] not in seen_urls:
            wallpapers.append(ex)
            seen_urls.add(ex['imageUrl'])

    if wallpapers:
        with open(target_file, 'w', encoding='utf-8') as f:
            json.dump(wallpapers, f, ensure_ascii=False, indent=2)
        print(f"Successfully updated wallpapers.json with {len(wallpapers)} photos.")
    else:
        print("No wallpapers scraped; kept existing file intact.")

if __name__ == '__main__':
    main()
