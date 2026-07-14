# Projeto: Jogo Corre Conde: A Sombra da Eternidade 

**Curso:** Ciência da Computação - UFRRJ

**Disciplina:** Computação Gráfica

**Professor:**  Bruno José Dembogurski, D.Sc.

**Semestre:** 2026.1

**Discentes:** Allan Sette Da Silva e Mayara da Silva Souza 


# Corre Conde 🦇

Jogo 2.5D de side-scroller desenvolvido em **Godot Engine 3.x**, onde você controla o Conde em uma fuga desesperada contra a luz do sol, enfrentando lobos, o Paladino Supremo e outras ameaças em busca dos fragmentos do Anel Ancestral.

## 📖 Sobre o jogo

O Conde precisa atravessar três fases — o **Castelo**, a **Floresta Sombria** e o **Cemitério Ancestral** — sempre correndo à frente de uma parede de luz solar mortal que o persegue. Pelo caminho, ele coleta pedaços de um Anel Ancestral, enfrenta lobos, desvia de crucifixos e estacas, e precisa derrotar o Paladino em cada fase para avançar.

### Principais mecânicas

- **Fuga da Luz Solar (`ZonaLuz`)**: uma parede de luz avança continuamente pelo cenário; ficar exposto a ela causa dano contínuo.
- **Sombra e Árvore Protetora**: coletar Pó Mágico planta uma árvore que desacelera o sol e cura o Conde.
- **Combate**: ataque com espada (lobos e Paladino), e sistema de *Parry* (capa de hipnose) para refletir estacas e anular golpes.
- **Coleta de Anel**: é necessário reunir fragmentos do Anel antes de poder derrotar o Paladino de cada fase.
- **Cronômetro e Ranking**: o tempo de cada fase é registrado, com uma tela de Ranking dos 10 melhores tempos salva localmente.
- **Editor de Fases**: um editor visual completo embutido no jogo, permitindo criar, salvar, carregar e testar fases customizadas no formato `.lvl`.
- **Tutorial dinâmico**: painéis de tutorial contextuais que aparecem conforme o jogador avança e encontra novas mecânicas.

## 🕹️ Controles

| Tecla | Ação |
|---|---|
| Seta Esquerda / Direita | Mover |
| Seta para Cima | Pular |
| Espaço | Atacar com espada |
| Z ou C | Capa de Hipnose (Parry — reflete estacas e bloqueia golpes) |
| Shift (segurar) | Correr |
| Esc | Menu de Pausa |

## 🗂️ Estrutura do projeto

```
├── Fase1.tscn / Fase1.gd          # Fase 1 — Castelo
├── Fase2.tscn / Fase2.gd          # Fase 2 — Floresta Sombria
├── Fase3.tscn / Fase3.gd          # Fase 3 — Cemitério Ancestral
├── Conde.tscn / Conde.gd          # Personagem principal (jogador)
├── Paladino.tscn / Paladino.gd    # Chefe de cada fase
├── LoboFase1.tscn / .gd           # Inimigo lobo
├── Lobisomem.tscn / .gd           # Lobisomem (fera especial)
├── ZonaLuz.gd                     # Lógica da parede de luz solar
├── ArvoreProtetora.tscn / .gd     # Árvore que gera sombra e cura
├── PedacoAnel.tscn / .gd          # Fragmentos coletáveis do Anel
├── Portal.tscn / .gd              # Portal de transição entre fases
├── Crucifixo.tscn / .gd           # Obstáculo de dano estático
├── Estaca.tscn / .gd              # Projétil disparado pelo Paladino
├── CaixaoQuebradico.tscn / .gd    # Plataforma que quebra ao ser pisada
├── EditorFases.tscn / .gd         # Editor visual de fases customizadas
├── LevelLoader.gd                 # Importador de níveis .lvl para 3D
├── FaseCarregada.tscn / .gd       # Controlador de fases customizadas
├── MenuPrincipal.tscn / .gd       # Menu principal
├── MenuPause.tscn / .gd           # Menu de pausa
├── MenuFasesCustom.tscn / .gd     # Lista de fases criadas pelo jogador
├── TutorialPanel.tscn / .gd       # Painel de tutorial contextual
├── TelaVitoria.tscn / .gd         # Tela de vitória + salvar recorde
├── TelaRanking.tscn / .gd         # Tela de ranking dos melhores tempos
├── GameOver.tscn / .gd            # Tela de derrota (varia por motivo)
├── CutsceneEntradaCastelo.tscn/.gd # Cutscene final
├── DadosJogo.gd                   # Singleton global (Autoload) — estado do jogo
└── *.shader                       # Shaders (portal, luz solar, céu, chão triplanar)
```

## ⚙️ Sistemas técnicos

- **`DadosJogo` (Autoload/Singleton)**: persiste dados entre cenas — fase atual, vida, pedaços coletados, cronômetro, flags de tutorial e ranking salvo em `user://ranking.json`.
- **Editor de Fases**: salva mapas customizados em `user://fases_custom/*.lvl`, com suporte a texturas, colisores, triggers e objetos (lobos, paladino, caixões, portais, etc.).
- **Shaders customizados**: efeitos de portal (`PortalShader`), parede de luz solar (`ZonaLuzShader`), céu dinâmico dia/noite (`CeuDiaShader`) e chão triplanar (`ChaoTriplanar`).
- **Áudio dinâmico**: trilha sonora alterna entre "mistério" e "chefe" conforme a proximidade do Paladino.

## 🚀 Como rodar

1. Instale o [Godot Engine 3.x](https://godotengine.org/download/) (versão compatível com o projeto).
2. Abra o Godot e importe a pasta do projeto (`project.godot`).
3. Rode a cena principal (`MenuPrincipal.tscn`) ou pressione **F5**.

## 📦 Build / Exportação

O projeto já conta com um preset de exportação configurado (`export_presets.cfg`) para **Windows Desktop**. Para exportar:

1. `Project > Export` no editor do Godot.
2. Selecione o preset **Windows Desktop**.
3. Exporte para `./Build/CorreConde.exe`.

## 🛠️ Tecnologias

- **Engine**: Godot 3.x (GDScript)
- **Renderização**: 2.5D (sprites 3D/billboard sobre cenário 3D)
- **Shaders**: GLSL via Godot Shader Language (`shader_type spatial`)

---



