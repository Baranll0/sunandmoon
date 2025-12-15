# GitHub Push Sorunu Çözümü

## Sorun
```
remote: Permission to Baranll0/sunandmoon.git denied
fatal: unable to access 'https://github.com/Baranll0/sunandmoon.git/': The requested URL returned error: 403
```

## Çözüm 1: Personal Access Token (Önerilen)

1. **GitHub'da Token oluştur:**
   - GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - "Generate new token (classic)"
   - İsim: "APK Build Token"
   - Scopes: `repo` (tüm repo yetkileri) seç
   - "Generate token" tıkla
   - **Token'ı kopyala** (bir daha gösterilmez!)

2. **Token ile push et:**
   ```bash
   git remote set-url origin https://<TOKEN>@github.com/Baranll0/sunandmoon.git
   git push -u origin main
   ```
   
   Veya:
   ```bash
   git push https://<TOKEN>@github.com/Baranll0/sunandmoon.git main
   ```

## Çözüm 2: SSH Key (Daha güvenli)

1. **SSH key oluştur:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Public key'i GitHub'a ekle:**
   - `cat ~/.ssh/id_ed25519.pub` ile key'i göster
   - GitHub → Settings → SSH and GPG keys → New SSH key
   - Key'i yapıştır ve kaydet

3. **Remote'u SSH'a çevir:**
   ```bash
   git remote set-url origin git@github.com:Baranll0/sunandmoon.git
   git push -u origin main
   ```

## Çözüm 3: GitHub Desktop (En kolay)

1. GitHub Desktop uygulamasını indir
2. Repo'yu aç
3. "Push origin" butonuna tıkla

## Çözüm 4: Manuel Upload (Hızlı ama sınırlı)

1. GitHub repo'ya git
2. "Upload files" butonuna tıkla
3. Tüm dosyaları sürükle-bırak
4. Commit message yaz
5. "Commit changes" tıkla

**Not:** Manuel upload ile GitHub Actions çalışır ama her değişiklikte tekrar upload etmen gerekir.

---

## Hızlı Çözüm (Token ile)

1. GitHub'da token oluştur (yukarıdaki adımlar)
2. Terminal'de:
   ```bash
   git remote set-url origin https://<TOKEN>@github.com/Baranll0/sunandmoon.git
   git push -u origin main
   ```

Token'ı `<TOKEN>` yerine yapıştır.

