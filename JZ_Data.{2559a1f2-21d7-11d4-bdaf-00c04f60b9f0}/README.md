# JZ-Toolkit 🚀

Plataforma unificada de ferramentas administrativas, automação de infraestrutura e gerenciamento de sistemas para técnicos e SysAdmins.

## 🛡️ Arquitetura e Segurança

Este toolkit foi projetado para execução rápida e segura, protegendo ferramentas sensíveis via camuflagem.

- **Modo Turbo (Mapeamento Virtual)**: Utiliza o comando `subst` para criar unidades de disco virtuais (`S:` e `T:`) instantâneas, garantindo performance e isolamento.
- **Camuflagem GUID**: As pastas de ferramentas utilizam extensões GUID do Windows para evitar acessos acidentais via Explorer.
- **Ambiente Limpo**: Execução baseada em arquivos temporários quando via Web, mantendo o sistema do hospedeiro íntegro.

## 📂 Estrutura do Projeto

- **`JZ-TOOLKIT.bat`**: Launcher principal unificado. Realiza a montagem do ambiente e inicia o painel PowerShell.
- **`JZ_Data.{2559a1f2-21d7-11d4-bdaf-00c04f60b9f0}`**: Pasta raiz de dados (camuflada).
- **`JZ-Toolkit.ps1`**: Dashboard principal com menus de SRE, Otimização e Rede.
- **`jz_init.ps1`**: Script de bootstrap para download e execução via GitHub.

## 🚀 Como Utilizar (One-Liner)

Para rodar o toolkit instantaneamente em qualquer máquina com Internet:

```powershell
irm t.ly/TI-JZ | iex
```

## 🛠️ Requisitos e Permissões

- **Privilégios**: Recomenda-se execução como **Administrador** para ferramentas de diagnóstico de hardware e rede.
- **Portabilidade**: O toolkit é auto-contido e não requer instalação prévia de dependências no sistema hospedeiro.

---
**JZ-Toolkit | SRE & Infrastructure Project**
