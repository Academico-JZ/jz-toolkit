# AHS SRE Toolkit Pro 🚀

Plataforma unificada de Engenharia de Confiabilidade (SRE) e Automação de Infraestrutura para o time de TI da AHS Indústria.

## 🛡️ Arquitetura de Segurança (Industrial Grade)

Este toolkit foi projetado para ser executado em máquinas de usuários finais sem expor credenciais ou permitir acesso indevido às ferramentas.

- **Zero-Cleartext**: Senhas não são armazenadas em texto plano. Utilizamos Hashing SHA-256 para validação.
- **Entrada Mascarada**: O login utiliza entrada invisível (anti-shoulder surfing).
- **Modo Turbo (Mapeamento Virtual)**: Utiliza o comando `subst` para criar unidades de disco virtuais (`S:` e `T:`) instantâneas, eliminando a lentidão de cópias via rede.
- **Camuflagem GUID**: As pastas de ferramentas são mascaradas como objetos de sistema do Windows. Ao tentar abrir via Explorer, o usuário é redirecionado ou recebe erro.

## 📂 Estrutura do Projeto

- **`MENU_DE_FERRAMENTAS.bat`**: Launcher para ferramentas legadas de Helpdesk (Otimizadores, WhatsApp, AnyDesk). Monta a **Unidade S:**.
- **`AHS-Toolkit.ps1`**: Novo Launcher PowerShell consolidado.
- **`ahs_init.ps1`**: Script de bootstrap para execução via comando (LAN ou GitHub).

## 🚀 Como Utilizar (Bootstrap)

Para executar o toolkit em qualquer máquina (requer Internet ou Rede Local):

```powershell
$token="OPCIONAL_TOKEN"; irm "https://raw.githubusercontent.com/Academico-JZ/ahs-toolkit/main/ahs_init.ps1" | iex
```

---
**AHS Indústria - SRE & Infrastructure Team**
