## GRE6 Tunnel Auto Setup Script (6to4 + GRE over IPv6)

A fully automated and interactive Bash script that creates a GRE6 + 6to4 tunnel between two servers (e.g., Iran <-> Foreign). It includes SSH validation, system checks, NAT setup, ping tests, and persistent connection check support.

---

### 🚀 Quick Start

To install and run the script:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/hamedjafari-ir/gre-tunnel-setup/main/setup-tunnel.sh)
```

This will download, install, and run the script under `/usr/local/bin/tunnel`. From that point onward, you can simply run:

```bash
tunnel
```

---

### 📜 Menu Options Explained

Each option in the interactive menu has an explanation below:

```
========= GRE6 Tunnel Setup Menu =========
1) Auto Setup Tunnel             # راه‌اندازی خودکار تونل بین دو سرور با اس اس اچ و تنظیم کامل
2) Manual Setup                  # راه‌اندازی دستی برای کاربران پیشرفته
3) Test Ping                     # بررسی پینگ از ایران به خارج و برعکس از طریق GRE و IPv6
4) Restart Server                # ری‌استارت کامل سیستم فعلی (با تأخیر 5 ثانیه)
5) About This Script             # اطلاعات درباره اسکریپت و نویسنده
6) Check GRE Tunnel Status       # بررسی فعال بودن تونل GRE و تست اتصال
7) Check Target IP Reachability  # بررسی فیلتر بودن یا دردسترس بودن یک IP خارجی خاص
8) Exit                          # خروج از منو
```

---

### 🔧 Requirements (نصب ابزارهای موردنیاز)

در صورت نبود ابزارهای زیر، اسکریپت به‌صورت خودکار آن‌ها را نصب می‌کند:

* `curl`
* `ip`
* `ssh`, `sshpass`
* `ping`, `ping6`
* `iptables`

---

### 🔄 Self-Update Feature

این اسکریپت در هر بار اجرا به‌صورت خودکار خودش را از GitHub به‌روزرسانی می‌کند، بنابراین همیشه آخرین نسخه را در اختیار دارید.

---

### 🧪 Tunnel Check and Status

اگر تونل با موفقیت راه‌اندازی شده باشد:

* در منوی بالا کنار عنوان، وضعیت `[CONNECTED]` نمایش داده می‌شود.
* گزینه‌ی 6 امکان بررسی فعال بودن GRE را دارد.
* گزینه‌ی 7 بررسی می‌کند که IP خاصی از داخل فیلتر است یا خیر.

---

### 📌 Developer

* Author: **Hamed Jafari**
* GitHub: [hamedjafari-ir](https://github.com/hamedjafari-ir)

For support or issues, please open an [Issue](https://github.com/hamedjafari-ir/gre-tunnel-setup/issues).

---

### 📜 License

MIT License

> This script was built to simplify tunnel creation between restricted networks and provide seamless IPv6 and GRE tunneling automation.
