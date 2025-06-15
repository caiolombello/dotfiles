# Configuração do GPG para Assinatura de Commits

Este guia explica como configurar o GPG para assinar commits no Git.

## Pré-requisitos

1. GPG instalado no sistema
2. Git configurado
3. Acesso ao terminal

## Passo a Passo

### 1. Instalação do GPG

#### Fedora/RHEL:
```bash
sudo dnf install gnupg2
```

#### Ubuntu/Debian:
```bash
sudo apt-get install gnupg2
```

#### Arch Linux:
```bash
sudo pacman -S gnupg
```

### 2. Gerando uma Nova Chave GPG

1. Inicie o processo de geração:
```bash
gpg --full-generate-key
```

2. Selecione as opções recomendadas:
   - Tipo de chave: RSA and RSA (default)
   - Tamanho da chave: 4096 bits
   - Validade: 0 (nunca expira)
   - Nome real: Seu nome completo
   - Email: Seu email
   - Comentário: (opcional)
   - Confirme as informações

3. Digite uma senha forte e segura

### 3. Listando suas Chaves

```bash
# Listar chaves públicas
gpg --list-secret-keys --keyid-format LONG

# Listar chaves privadas
gpg --list-secret-keys --keyid-format LONG
```

### 4. Exportando a Chave Pública

```bash
# Substitua KEY_ID pela ID da sua chave
gpg --armor --export KEY_ID
```

### 5. Configurando o Git para Usar GPG

1. Configure o Git para usar sua chave:
```bash
git config --global user.signingkey KEY_ID
```

2. Habilite a assinatura automática de commits:
```bash
git config --global commit.gpgsign true
```

3. Configure o GPG para usar o agente:
```bash
echo "use-agent" >> ~/.gnupg/gpg.conf
```

### 6. Configurando o GPG Agent

1. Adicione ao seu `.zshrc` ou `.bashrc`:
```bash
export GPG_TTY=$(tty)
```

2. Inicie o agente GPG:
```bash
gpgconf --launch gpg-agent
```

### 7. Adicionando a Chave ao GitHub/GitLab

1. Copie sua chave pública:
```bash
gpg --armor --export KEY_ID | pbcopy  # macOS
gpg --armor --export KEY_ID | xclip -selection clipboard  # Linux
```

2. Adicione a chave nas configurações do GitHub/GitLab:
   - GitHub: Settings > SSH and GPG keys > New GPG key
   - GitLab: Preferences > GPG Keys

### 8. Verificando a Configuração

1. Faça um commit de teste:
```bash
echo "test" > test.txt
git add test.txt
git commit -m "test: GPG signing"
```

2. Verifique a assinatura:
```bash
git log --show-signature -1
```

## Solução de Problemas

### Erro: "gpg failed to sign the data"

1. Verifique se o GPG agent está rodando:
```bash
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

2. Verifique a configuração do Git:
```bash
git config --list | grep gpg
```

3. Verifique se a chave está correta:
```bash
gpg --list-secret-keys --keyid-format LONG
```

### Erro: "No pinentry program available"

1. Instale o pinentry:
```bash
# Fedora
sudo dnf install pinentry

# Ubuntu
sudo apt-get install pinentry-gtk2

# Arch
sudo pacman -S pinentry
```

2. Configure o pinentry:
```bash
echo "pinentry-program /usr/bin/pinentry-gtk-2" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

## Boas Práticas

1. Mantenha sua chave privada segura
2. Use uma senha forte
3. Faça backup da sua chave
4. Revogue a chave se comprometida
5. Use chaves diferentes para diferentes propósitos (pessoal, trabalho)

## Backup e Restauração

### Backup
```bash
# Exportar chave privada
gpg --export-secret-keys KEY_ID > private.key

# Exportar chave pública
gpg --export KEY_ID > public.key

# Exportar revogação
gpg --gen-revoke KEY_ID > revoke.asc
```

### Restauração
```bash
# Importar chave privada
gpg --import private.key

# Importar chave pública
gpg --import public.key
```

## Recursos Adicionais

- [Documentação oficial do GPG](https://gnupg.org/documentation/)
- [GitHub - Managing commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification)
- [GitLab - GPG Signatures](https://docs.gitlab.com/ee/user/project/repository/gpg_signed_commits/)
