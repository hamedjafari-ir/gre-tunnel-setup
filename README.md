## GRE6 Tunnel Auto Setup Script (6to4 + GRE over IPv6)

A fully automated and interactive Bash script that creates a GRE6 + 6to4 tunnel between two servers (e.g., Iran <-> Foreign). It includes SSH validation, system checks, NAT setup, ping tests, and persistent connection check support.

---

## 🌐 دو زبانه / Bilingual Instructions

🇬🇧 **English** | 🇮🇷 **فارسی**

---

### 🚀 Quick Start / شروع سریع

```bash
bash <(curl -Ls https://raw.githubusercontent.com/hamedjafari-ir/gre-tunnel-setup/main/setup-tunnel.sh)
```

🇬🇧 This command will install the tunnel script and run it.
🇮🇷 این دستور اسکریپت را نصب و اجرا می‌کند.

After installation:

```bash
tunnel
```

🇬🇧 From now on, run `tunnel` to launch the script.
🇮🇷 از این به بعد با زدن دستور `tunnel` اسکریپت اجرا می‌شود.

---

### 📜 Menu Options Explained / توضیح منو

```
========= GRE6 Tunnel Setup Menu =========
1) Auto Setup Tunnel              # 🇬🇧 Auto setup between two servers via SSH
                                 # 🇮🇷 راه‌اندازی خودکار تونل بین دو سرور

2) Manual Setup                  # 🇬🇧 Advanced users can manually configure
                                 # 🇮🇷 حالت دستی برای کاربران حرفه‌ای

3) Test Ping                     # 🇬🇧 Test ping from Iran <-> Foreign
                                 # 🇮🇷 بررسی پینگ از ایران به خارج و بالعکس

4) Restart Server                # 🇬🇧 Restart current server after delay
                                 # 🇮🇷 ریستارت سرور با تأخیر 5 ثانیه

5) About This Script             # 🇬🇧 Information about the script and author
                                 # 🇮🇷 معرفی اسکریپت و نویسنده

6) Check GRE Tunnel Status       # 🇬🇧 Check GRE status and tunnel connection
                                 # 🇮🇷 بررسی وضعیت تونل GRE

7) Check Target IP Reachability  # 🇬🇧 Check if a foreign IP is reachable
                                 # 🇮🇷 بررسی فیلتر بودن یا نبودن یک IP خارجی

8) Exit                          # 🇬🇧 Exit the menu
                                 # 🇮🇷 خروج از منو
```

---

### 🔧 Requirements / پیش‌نیازها

🇬🇧 The script automatically installs required tools if missing:
🇮🇷 اگر ابزارهای موردنیاز نصب نباشند، اسکریپت آن‌ها را نصب می‌کند:

* `curl`
* `ip`
* `ssh`, `sshpass`
* `ping`, `ping6`
* `iptables`

---

### 🔄 Self-Update / به‌روزرسانی خودکار

🇬🇧 The script checks GitHub and updates itself every time it runs.
🇮🇷 اسکریپت در هر بار اجرا خودش را از گیت‌هاب به‌روز می‌کند.

---

### 🧪 Tunnel Status / وضعیت تونل

* 🇬🇧 If tunnel is active, `[CONNECTED]` appears in the menu header.

* 🇮🇷 اگر تونل فعال باشد، در منوی بالا وضعیت `[CONNECTED]` نمایش داده می‌شود.

* 🇬🇧 Option 6 checks GRE tunnel health.

* 🇮🇷 گزینه 6 بررسی فعال بودن GRE است.

* 🇬🇧 Option 7 tests if a foreign IP is filtered or not.

* 🇮🇷 گزینه 7 بررسی می‌کند که IP خاصی فیلتر هست یا خیر.

---

### 👨‍💻 Developer

* Author: **Hamed Jafari**
* GitHub: [hamedjafari-ir](https://github.com/hamedjafari-ir)

🇬🇧 For issues, open an [Issue](https://github.com/hamedjafari-ir/gre-tunnel-setup/issues).
🇮🇷 برای پشتیبانی، یک Issue در GitHub باز کنید.

---

### 📜 License / مجوز

MIT License

> 🇬🇧 This script simplifies GRE+IPv6 tunnel setup for restricted networks.
> 🇮🇷 این اسکریپت راه‌اندازی تونل GRE+IPv6 را در شبکه‌های محدود آسان می‌کند.
