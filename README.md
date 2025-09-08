# Goylin

## Descrição

Goylin é uma distribuição Linux baseada em Arch, desenvolvida para o Instituto Federal de Goiás (IFG), visando um sistema leve e otimizado para as necessidades da instituição em salas de aula e laboratórios. Incentivando alternativas open-source, essa escolha promove liberdade de software, reduz custos e incentiva colaboração.
Suporte hardwares antigos, ideal para máquinas modestas em escolas públicas, promovendo inclusão digital ao permitir acesso tecnológico a alunos e professores de baixa renda, reduzindo desperdício eletrônico e democratizando a educação digital.


## Dependencias
```bash
sudo pacman -S --needed bash coreutils util-linux pacman arch-install-scripts grep awk sed sudo lsof attr wipefs timedatectl gimp inkscape
```

## Configuração
Arquivos com sufixo `.proto` devem ser configurados e renomeados.

- installer/utils/secrets.sh.proto
- installer/utils/pacman_goylin.conf.proto
- utils/pacman_dev.conf.proto
- installer/etc/hosts.proto


## Instalador - installer/
O **Instalador Goylin** é um script Bash que automatiza a instalação.
- Instalação padrão requer conexão a um repositorio Goylin.
- Instalação de desenvolmimento requer copia local do repositório Goylin em `/srv/http/`.

```bash
sudo ./goylin-installer.sh [-d] [-l] [-*]
```

### Flags

- `-d`: Usa configurações padrão (pula prompts e instala a configuração padrão em `installer/utils/installConf.sh`.)
- `-l`: Instalação para desenvolvimento local.
- `-*`: Ajuda

### Opções de Configuração
Sem a flag `-d`, o script solicita:

- **Dispositivo Alvo**: Ex.: `sda`, `nvme0n1`.
- **Tipo de Alvo**: HDD, NVMe ou SSD (padrão: `SSD`).
- **Manter Partição Home**: `y` ou `N`.
- **Tipo de CPU**: AMD, Intel ou Intel sem Vulkan (padrão: Intel sem Vulkan, para `Intel HD Graphics 4000` ou inferior).
- **Perfil**: Perfil de instalação (padrão: `Base`).


## Contribuição
Contribuições são bem-vindas! Siga estas etapas:

1. Faça um fork do repositório.
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`).
3. Commit suas alterações (`git commit -m 'Adiciona nova funcionalidade'`).
4. Push para a branch (`git push origin feature/nova-funcionalidade`).
5. Abra um Pull Request.