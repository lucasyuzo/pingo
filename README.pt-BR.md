<div align="center">

# 🐾 pingo

**Seu companheiro fiel para encontrar repositórios locais.**

Shell puro · zero dependências · zsh e bash · macOS, Linux e Windows (Git Bash)

[English](README.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)

</div>

```
  pingo  · 5 repositórios

  ❯ 1  api       ~/work/api           ⎇ main
    2  web       ~/work/web-frontend  ⎇ feat/login
    3  infra     ~/work/infra         ⎇ develop
    4  dotfiles  ~/dotfiles           ⎇ master
    5  old-proj  ~/old/proj           ✗ não encontrado

  ⏎ abrir   a adicionar   d remover   m mover   s config   ? ajuda   q sair
```

Digite `pingo`, escolha o repositório com as setas, aperte Enter: pronto, você está lá.
Ou pule o menu com `pingo api` ou `pingo 2`.

## Funcionalidades

- **Menu interativo** com setas (ou `j`/`k`), salto por número e atalhos para adicionar, remover, reordenar e renomear.
- **Atalhos diretos**: `pingo <alias>`, `pingo <nome-da-pasta>` ou `pingo <posição>`.
- **A sua ordem**: a lista aparece na ordem que você escolher. Reordene com `m` no menu ou com `pingo mv`.
- **Branch atual** ao lado de cada repositório, lida direto do `.git/HEAD` (instantâneo, inclusive no Windows).
- **Repositórios inexistentes** aparecem em vermelho; `pingo prune` remove todos.
- **Inglês e Português (Brasil)**, detectados pelo sistema. Qualquer outro idioma com um único arquivo.
- **Autocompletar com Tab** no zsh e no bash.
- **Shell puro**: só builtins do bash/zsh. Funciona no zsh ≥ 5 e no bash ≥ 3.2.

## Instalação

Clone o repositório e rode o instalador, que adiciona **uma linha** ao arquivo
de inicialização do seu shell.

```sh
git clone https://github.com/lucasyuzo/pingo ~/.pingo
~/.pingo/install.sh
```

O instalador pergunta onde o pingo deve ser carregado e já sugere o arquivo certo para o seu shell:

| Opção             | Quando usar                                                                |
|-------------------|----------------------------------------------------------------------------|
| `~/.zshrc`        | zsh (padrão do macOS)                                                      |
| `~/.bash_profile` | bash no **Windows (Git Bash)** e no macOS, que abrem *login shells*        |
| `~/.bashrc`       | bash no Linux. O pingo garante também que o `~/.bash_profile` carregue o `~/.bashrc` |

Depois abra um novo terminal (ou faça `source` do arquivo) e cadastre seu primeiro repositório:

```sh
pingo add ~/work/api        # o alias padrão é o nome da pasta
pingo add . web             # diretório atual, com o alias "web"
pingo                       # abre o menu
```

<details>
<summary>Instalação não interativa (scripts, CI, setup do time)</summary>

```sh
~/.pingo/install.sh --rc ~/.zshrc --lang pt-BR --yes
```

| Flag            | Descrição                                            |
|-----------------|------------------------------------------------------|
| `--rc <arquivo>`| arquivo de inicialização que carrega o pingo         |
| `--lang <código>`| idioma da interface (padrão: detectado pelo sistema) |
| `-y`, `--yes`   | usa os padrões, sem perguntas                        |

</details>

<details>
<summary>Por que uma linha no rc e não um binário no PATH?</summary>

Um programa no `PATH` roda em um processo filho: ele consegue mudar o *próprio*
diretório, mas nunca o diretório do shell em que você está digitando. Por isso
ferramentas de navegação (nvm, zoxide, autojump…) são **funções** de shell
carregadas pelo arquivo de inicialização. Na prática, usar o pingo é igual a
usar qualquer comando.

</details>

## Uso

| Comando                          | Descrição                                       |
|----------------------------------|-------------------------------------------------|
| `pingo`                          | abre o menu interativo                          |
| `pingo <n\|alias>`               | vai direto para um repositório                  |
| `pingo ls`                       | lista os repositórios                           |
| `pingo add <caminho> [alias]`    | cadastra um repositório (no fim da lista)       |
| `pingo rm <n\|alias> [-y]`       | remove um repositório da lista                  |
| `pingo mv <n\|alias> <posição>`  | move um repositório para outra posição          |
| `pingo rename <n\|alias> <novo>` | altera o alias                                  |
| `pingo prune`                    | remove repositórios que não existem mais        |
| `pingo config`                   | mostra configurações e locais dos arquivos      |
| `pingo config lang [código]`     | lista os idiomas ou troca o idioma              |
| `pingo update`                   | atualiza o pingo (`git pull` na instalação)     |
| `pingo help`, `pingo --version`  | ajuda e versão                                  |

### Teclas do menu

| Tecla                    | Ação                                             |
|--------------------------|--------------------------------------------------|
| `↑` `↓` / `j` `k`        | navegar (`Home`/`End` e `g`/`G` também funcionam) |
| `Enter`                  | ir para o repositório selecionado                |
| `1`–`9`                  | pular para uma posição                           |
| `a`                      | adicionar o diretório atual                      |
| `d`                      | remover o selecionado (pede confirmação)         |
| `m`                      | mover: pega o item, use `↑` `↓`, solte com Enter |
| `r`                      | renomear (alterar alias)                         |
| `s`                      | configurações (idioma)                           |
| `?`                      | ajuda                                            |
| `q` / `Esc`              | sair                                             |

### Aliases e caminhos

- O alias é opcional. Sem ele, o repositório aparece com o nome da pasta, e
  `pingo <nome-da-pasta>` funciona desde que esse nome seja único.
- Um alias não pode ser só números (números são posições), ter espaços ou `|`,
  começar com `-` nem ser um comando do pingo.
- O mesmo diretório não pode ser cadastrado duas vezes.
- No Windows você pode usar `C:\Users\eu\api`, `C:/Users/eu/api` ou `/c/Users/eu/api`;
  o pingo guarda todos do mesmo jeito.

## Configuração

Tudo fica em `~/.config/pingo/` (ou `$XDG_CONFIG_HOME/pingo/`):

| Arquivo    | Conteúdo                                                        |
|------------|-----------------------------------------------------------------|
| `repos`    | um repositório por linha, `alias\|caminho`, na ordem de exibição |
| `config`   | configurações, `chave=valor` com comentários                    |
| `lang/`    | suas traduções (opcional)                                       |

Os dois arquivos são texto puro e podem ser editados à mão.

### Idioma

O instalador escolhe o idioma pelo sistema (`$LANG` no macOS/Linux, a
localidade do Windows no Git Bash). Para trocar quando quiser:

- pressione `s` no menu, ou
- rode `pingo config lang en`, ou
- edite `lang=` em `~/.config/pingo/config`.

#### Adicionando um idioma

1. Copie [`lang/en.sh`](lang/en.sh) para `~/.config/pingo/lang/<código>.sh` (ex.: `es.sh`).
2. Traduza os textos (mantenha cada `%s`).
3. Rode `pingo config lang <código>`.

Chaves não traduzidas usam o texto em inglês, então uma tradução parcial funciona.
Pull requests com novos idiomas são muito bem-vindos!

## Desinstalação

```sh
~/.pingo/uninstall.sh        # pergunta se deve apagar sua lista e configurações
rm -rf ~/.pingo              # remove os arquivos do programa
```

`--yes` mantém seus dados sem perguntar; `--purge` apaga.

## Desenvolvimento

```sh
tests/run.sh                 # roda os testes no bash, zsh e (no macOS) bash 3.2
SHELLS="zsh" tests/run.sh    # um único shell
```

O CI roda a suíte no Linux, macOS e Windows (Git Bash) a cada push.

## Por que "pingo"?

Pingo é o nome do meu cachorro. 🐕

O Pingo é um cocker spaniel, e cocker spaniel já nasce com um faro que
deveria ser proibido por lei. Caiu uma migalha na cozinha? Ele acha antes de
ela chegar no chão. Escondeu um petisco no fundo do armário? Ele já está
sentado na frente da porta, te encarando.

Esta ferramenta funciona do mesmo jeito, só que sem a baba: diga para onde
quer ir e ela fareja o repositório para você. Nada de
`cd ../../../onde/era/mesmo`. Nada de ficar cavando pastas. É só `pingo`,
Enter, e pronto.

Bom garoto. 🦴

## Licença

[MIT](LICENSE)
