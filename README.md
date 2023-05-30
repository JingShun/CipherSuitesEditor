# CipherSuitesEditor
透過批次檔來新增編輯加密套件與協定

## 由來

因為弱掃發現高風險漏洞，
需要停用3DES、RC4等加密套件，
且一台一台通知太麻煩，打算直接派送，
所以才有了這篇

## 檔案介紹
### CipherSuitesEditor.bat
CipherSuitesEditor.bat是主程式，以系統管理員身分運行即可

功能
- 備份現有設定
- 停用過時的協定
- 移除不安全的加密套件
- 加入高強度的加密套件(避免有的人是空值導致https都無法連線，但需要自行維護內容)

### DisableCiphers.reg
- 停用不安全的設定
- 不選擇刪除是為了因應部分舊版作業系統預設是啟用的，所以必須指定停用以防萬一

### run.rpx
瑞思Rapix派送專用檔案

## 調整教學
- 登錄檔DisableCiphers.reg 可自行調整
- 因應調整加密套件有分本地系統的與群組原則的會分開調整，視需求可自行調整

|方法|用法|描述|
|---|---|---|
|removePolicyCipherSuites|`call :removePolicyCipherSuites 3DES`|移除所有出現關鍵字3DES的套件(群組原則, 立即生效)|
|removeSystemCipherSuites|`call :removeSystemCipherSuites 3DES`|移除所有出現關鍵字3DES的套件(本地系統, 重啟生效)|
|addPolicyCipherSuites |`call :addPolicyCipherSuites  "TLS_E...,TLS_ECD...,..."`|加入指定的套件(群組原則, 立即生效)|
|addSystemCipherSuites |`call :addSystemCipherSuites  "TLS_E...,TLS_ECD...,..."`|加入指定的套件(本地系統, 重啟生效)|

p.s. 
1. 因為移除是依靠關鍵字來移除，因此越完整越好，避免誤刪
2. 新增的參數前號需要雙引號，不同套件可用逗號區隔，舉例 `call :addPolicyCipherSuites  "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"`

## 紀錄

2023/05/29
- 考慮GPO、本地的加密套件設定而調整

2023/05/23
- 重構

2023/05/15
- 建立
