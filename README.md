# 🚀 Marzban One-Line Setup Script (YNL)

အခု Script ကတော့ Ubuntu 24.04 နဲ့ အထက် VPS တွေမှာ **Marzban Dashboard**, **SSL Certificate (ESSL)**, နဲ့ **Custom Subscription Template** တွေကို တစ်ခါတည်း အပြီးအစီး Setup လုပ်ပေးမယ့် One-line script ဖြစ်ပါတယ်။

## ✨ အဓိကပါဝင်တဲ့ Features များ
* **YNL Logo Banner**: လှပသပ်ရပ်တဲ့ Terminal UI။
* **Automated Installation**: Marzban ကို အလိုအလျောက် သွင်းပေးခြင်း။
* **SSL Automation**: `essl.sh` ကိုသုံးပြီး Domain အတွက် SSL ထုတ်ပေးခြင်း။
* **Custom Template**: Samimifar ရဲ့ Subscription Template ကို တစ်ခါတည်း ထည့်သွင်းပေးခြင်း။
* **Auto-Configuration**: `.env` ဖိုင်ထဲက Uvicorn နဲ့ Telegram Bot settings တွေကို အလိုအလျောက် ပြင်ဆင်ပေးခြင်း။

## 🛠 အသုံးပြုနည်း (Installation)

သင့်ရဲ့ VPS (Ubuntu 24.04 အကြံပြုသည်) မှာ အောက်ပါ command ကို ကူးယူပြီး Run လိုက်ပါ။

```bash
bash <(curl -sL https://raw.githubusercontent.com/yannaing86tt/My-Marzban-Script/refs/heads/main/my_marzban_script.sh)
```
