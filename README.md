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

**🇬🇧** This command will install the tunnel script and run it.
**🇮🇷** این دستور اسکریپت را نصب و اجرا می‌کند.

After installation, use:

```bash
tunnel
```

**🇬🇧** From now on, run `tunnel` to launch the script.
**🇮🇷** از این به بعد برای اجرای اسکریپت، فقط کافی‌ست دستور تانل را در ترمینال وارد کنید.

---

### 📜 Menu Options Explained / توضیح منو

```
========= GRE6 Tunnel Setup Menu =========
1) Auto Setup Tunnel              # 🇬🇧 Auto setup between two servers via SSH
                                 # 🇮🇷 راه‌اندازی خودکار تانل بین دو سرور

2) Manual Setup                  # 🇬🇧 Advanced users can manually configure
                                 # 🇮🇷 راه‌اندازی دستی برای کاربران حرفه‌ای

3) Test Ping                     # 🇬🇧 Test ping from Iran <-> Foreign
                                 # 🇮🇷 بررسی پینگ از ایران به خارج و بالعکس

4) Restart Server                # 🇬🇧 Restart current server after delay
                                 # 🇮🇷 ریستارت سرور با تأخیر ۵ ثانیه

5) About This Script             # 🇬🇧 Information about the script and author
                                 # 🇮🇷 اطلاعات درباره اسکریپت و نویسنده

6) Check GRE Tunnel Status       # 🇬🇧 Check GRE status and tunnel connection
                                 # 🇮🇷 بررسی وضعیت تانل GRE

7) Check Target IP Reachability  # 🇬🇧 Check if a foreign IP is reachable
                                 # 🇮🇷 بررسی فیلتر بودن یا نبودن یک IP خارجی

8) Exit                          # 🇬🇧 Exit the menu
                                 # 🇮🇷 خروج از منو
```

---

### 🔧 Requirements / پیش‌نیازها

**🇬🇧** The script automatically installs required tools if missing:
**🇮🇷** در صورت عدم وجود ابزارهای لازم، اسکریپت آن‌ها را به‌طور خودکار نصب می‌کند:

* `curl`
* `ip`
* `ssh`, `sshpass`
* `ping`, `ping6`
* `iptables`

---

### 🔄 Self-Update / به‌روزرسانی خودکار

**🇬🇧** The script checks GitHub and updates itself every time it runs.
**🇮🇷** اسکریپت در هر بار اجرا خودش را از گیت‌هاب به‌روزرسانی می‌کند.

---

### 🧪 Tunnel Status / وضعیت تانل

* **🇬🇧** If tunnel is active, `[CONNECTED]` appears in the menu header.
  **🇮🇷** اگر تانل فعال باشد، در منوی بالا وضعیت `[CONNECTED]` نمایش داده می‌شود.

* **🇬🇧** Option 6 checks GRE tunnel health.
  **🇮🇷** گزینه ۶ بررسی سلامت تانل GRE است.

* **🇬🇧** Option 7 tests if a foreign IP is filtered or not.
  **🇮🇷** گزینه ۷ بررسی می‌کند که آیا یک IP خارجی فیلتر است یا نه.

---

### 👨‍💻 Developer

* Author: **Hamed Jafari**
* GitHub: [hamedjafari-ir](https://github.com/hamedjafari-ir)

**🇬🇧** For issues, open an [Issue](https://github.com/hamedjafari-ir/gre-tunnel-setup/issues).
**🇮🇷** برای پشتیبانی، یک Issue در GitHub باز کنید.

---

### 📜 License / مجوز

MIT License

> **🇬🇧** This script simplifies GRE+IPv6 tunnel setup for restricted networks.
> **🇮🇷** این اسکریپت راه‌اندازی تانل GRE+IPv6 را برای شبکه‌های محدود ساده می‌کند.
