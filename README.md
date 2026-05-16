
# 🦇 **Corre Conde** 

**Corre Conde** é um jogo de plataforma e sobrevivência 2.5D focado em mecânicas estritas de luz e sombra. Desenvolvido inteiramente em **C estruturado e OpenGL puro** (sem a abstração de motores gráficos como Unity ou Godot), o projeto explora conceitos fundamentais de Computação Gráfica operando diretamente no hardware de vídeo.

Nesta aventura com toques de terror psicológico e urgência, você controla um Lorde Vampiro ancestral que simplesmente perdeu a hora de voltar para casa. O sol está nascendo e os feixes de luz solar são letais. O objetivo é manipular elementos do cenário para criar sombras seguras, resolvendo puzzles espaciais para conseguir atravessar a montanha e chegar à segurança do seu Castelo antes de virar cinzas.

### Engenharia e Técnicas de CG Aplicadas

Este projeto foi construído para validar o domínio de processamento de imagens e síntese visual matemática no pipeline gráfico, contendo:

* **Linguagem Base:** C puro (abordagem procedural e estruturada).
* **API Gráfica:** OpenGL (via GLUT/FreeGLUT).
* **Transformações e Interação Espacial:** Testes de intersecção geométrica de volumes envolventes baseados em AABB (*Axis-Aligned Bounding Box*) e manipulação contínua de matrizes de translação para simular pulos e quedas.
* **Mecânica de Luz e Sombra:** Algoritmos de checagem de área para intersecção de polígonos mortais (feixes de luz) com aplicação de *Alpha Blending*.
* **Câmera Virtual:** Translação inversa da cena (`glTranslatef`) e manipulação de matrizes de projeção (`gluOrtho2D`) para alternância entre Câmera de Ação (Follow) e Câmera Tática de Planejamento.
* **Pipeline Visual:** Implementação de FOG (Névoa translúcida com Gradiente Linear) e Sistemas de Partículas primitivos para simulação de destruição.

---

*Projeto desenvolvido como trabalho final para a disciplina de Computação Gráfica.*

---

##  Como Compilar e Executar o Jogo (Linux / Ubuntu)

Para rodar o **Corre Conde** no ambiente Linux (especificamente homologado no Ubuntu 24.04 LTS), siga os passos abaixo através do terminal para instalar as dependências, compilar o código-fonte em C e executar o protótipo.

### 1. Instalação das Dependências

Antes de realizar a compilação, é necessário instalar o ecossistema de desenvolvimento essencial do Linux (GCC e Make) junto com as bibliotecas de desenvolvimento do OpenGL e do FreeGLUT. Para isso, execute o comando:

```bash
sudo apt update && sudo apt install build-essential freeglut3-dev -y

```

### 2. Compilação do Código

Com o terminal aberto na mesma pasta onde está localizado o arquivo `main.c`, utilize o compilador GCC para gerar o executável. É fundamental incluir as *flags* de vinculação (`-lGL -lGLU -lglut`) para que o sistema conecte corretamente o código com a API gráfica do hardware:

```bash
gcc main.c -o corre_conde -lGL -lGLU -lglut

```

### 3. Execução do Jogo

Após a compilação ser concluída sem erros, um arquivo executável binário chamado `corre_conde` terá sido criado no diretório. Para iniciar o jogo, basta rodar o comando:

```bash
./corre_conde

```
---
