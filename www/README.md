# 💳 SISTEMA GFEC — Finanças do Casal (Web, Android & iOS)

Sistema moderno e inteligente de gestão financeira compartilhada para casais. Projetado com estética de fintech premium, proteção de privacidade individual, automatização dos cálculos de faturas, acertos mútuos e suporte nativo para **Android**, **iOS** e **PWA Web**.

---

## 🏗️ Arquitetura do Sistema

```text
                 INTERNET
                    │
                    ▼
              Cloudflare
          HTTPS + proteção
                    │
                    ▼
          Frontend / PWA
          HTML / CSS / JS
                    │
                    │ API HTTPS
                    ▼
             Backend / API (Supabase)
                    │
             ┌──────┴──────┐
             ▼             ▼
          Banco de      Storage
        dados Postgres  arquivos
```

---

## ☁️ Guia Completo de Deploy na Nuvem (Cloudflare + Supabase)

### 1. 🗄️ Backend, API & Banco de Dados (Supabase)
1. Crie uma conta gratuita em [supabase.com](https://supabase.com) e crie um novo projeto.
2. Acesse o menu **SQL Editor > New Query**.
3. Copie todo o conteúdo do arquivo [`schema.sql`](file:///c:/Users/Samuel/Documents/SISTEMA%20GFEC/schema.sql) e clique em **Run**.
4. Acesse **Project Settings > API** e copie os valores:
   - `Project URL`
   - `anon / public key`
5. No arquivo [`index.html`](file:///c:/Users/Samuel/Documents/SISTEMA%20GFEC/index.html), substitua as variáveis no topo do script:
   ```javascript
   const SUPABASE_URL = "https://seu-projeto.supabase.co";
   const SUPABASE_KEY = "sua-chave-anon-aqui";
   ```

#### 🔓 Desativar Confirmação por E-mail (Recomendado para Login Rápido)
1. No painel do **Supabase**, vá em **Authentication** > **Providers**.
2. Selecione **Email**.
3. Desmarque a opção **"Confirm email"** e clique em **Save**.

---

### 2. ⚡ Hospedagem no Cloudflare Pages (Frontend / PWA com HTTPS & CDN)
O **Cloudflare Pages** oferece hospedagem gratuita, certificado SSL/HTTPS automático, proteção contra ataques e velocidade global via CDN.

#### Opção A: Deploy via Repositório Git (GitHub / GitLab)
1. Suba o código do projeto para o seu GitHub.
2. Acesse o painel do [Cloudflare Dashboard](https://dash.cloudflare.com) e navegue até **Workers & Pages**.
3. Clique em **Create Application > Pages > Connect to Git**.
4. Selecione o seu repositório `SISTEMA GFEC`.
5. Em **Build Settings**:
   - **Framework preset**: `None` (HTML/JS Estático)
   - **Build command**: `npm run build`
   - **Build output directory**: `www`
6. Clique em **Save and Deploy**. Em menos de 1 minuto, seu app estará no ar com HTTPS gratuito (ex: `gfec.pages.dev`).

#### Opção B: Deploy Direto via Wrangler (CLI do Cloudflare)
Você também pode fazer o upload direto do seu terminal:
```bash
npx wrangler pages deploy www --project-name=financas-gfec
```

---

## 📱 Como Compilar para Android & iOS

### 🤖 1. Android (APK / Android Studio)
1. Compile a versão web atualizada:
   ```bash
   npm run cap:sync
   ```
2. Abra o projeto no **Android Studio**:
   ```bash
   npm run cap:open:android
   ```
3. No Android Studio, clique em **Build > Build Bundle(s) / APK(s) > Build APK(s)**. O arquivo `.apk` será gerado na pasta `android/app/build/outputs/apk/debug/`.

---

### 🍎 2. iOS (iPhone / Xcode)
1. No macOS com Xcode instalado, sincronize e abra o projeto:
   ```bash
   npm run cap:sync
   npm run cap:open:ios
   ```
2. Selecione seu iPhone ou o Simulador no Xcode e clique no botão **Play (Run)**.

---

### 📲 3. Instalação Instantânea como PWA (Sem precisar de Lojas)
Uma vez hospedado no Cloudflare Pages:
- **No Android (Chrome)**: Acesse o link no Chrome e clique no banner ou menu (3 pontos) > **"Instalar aplicativo"**.
- **No iPhone (Safari)**: Acesse no Safari, toque no botão **Compartilhar** (quadrado com seta) > **"Adicionar à Tela de Início"**.

---

## 📂 Estrutura do Projeto

```
SISTEMA GFEC/
├── android/          # Projeto nativo Android (Gradle / Android Studio)
├── ios/              # Projeto nativo iOS (Xcode)
├── icons/            # Ícones nativos (SVG, PNG, Apple Touch Icon)
├── scripts/
│   └── build.js      # Script de bundle web para o Capacitor (pasta www/)
├── www/              # Pasta de distribuição compilada (Cloudflare / Capacitor)
├── index.html        # Aplicação web SPA (Design System + Regras de Negócio)
├── manifest.json     # Manifesto PWA com atalhos e modo standalone
├── sw.js             # Service Worker para suporte Offline
├── capacitor.config.json # Configuração do Capacitor (Android & iOS)
├── package.json      # Scripts NPM e dependências
├── schema.sql        # Script SQL para o Supabase (Tabelas, RLS e Políticas)
└── README.md         # Documentação e Arquitetura do Sistema
```
