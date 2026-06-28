#include <GL/freeglut.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// =====================================================================
// CORRE CONDE: A SOMBRA DA ETERNIDADE - VERSÃO 4.5 (PACING & DRAMA)
// Defesa de Computação Gráfica - UFRRJ (Prof. Bruno Dembogurski)
// Discentes: Allan Sette Da Silva e Mayara da Silva Souza
// =====================================================================

#define TELA_LARGURA 800
#define TELA_ALTURA 600
#define NUM_PLATAFORMAS 8
#define NUM_ALHOS 3

#define BTN_X1 250
#define BTN_X2 550
#define BTN_INICIAR_Y1 350
#define BTN_INICIAR_Y2 400
#define BTN_HIST_Y1    270
#define BTN_HIST_Y2    320
#define BTN_SAIR_Y1    190
#define BTN_SAIR_Y2    240

typedef enum { 
    ESTADO_MENU, 
    ESTADO_FASE1, 
    ESTADO_FASE2, 
    ESTADO_PAUSE, 
    ESTADO_GAME_OVER, 
    ESTADO_VITORIA, 
    ESTADO_SALVAR_RECORDE,
    ESTADO_HISTORICO 
} EstadoJogo;

EstadoJogo estadoAtual = ESTADO_MENU;
EstadoJogo faseAtualRoteada = ESTADO_FASE1; 

typedef struct {
    float x, y, largura, altura;
    float velX, velY;
    float velocidade;
    bool noChao;
    float energia_vital;
    int fragmentos_anel;
    float tempoPiscar; 
    float temporizadorParry; 
} Jogador;

typedef struct { float x, y, largura, altura; } Plataforma;
typedef struct { float x, y, largura, altura; bool ativo; } ObjetoDano;
typedef struct { float x, y, largura, altura; bool viva; } Estaca;
typedef struct { float x, y, largura, altura; bool visivel; } Trofeu;

typedef struct { float x, y; bool ativo; } PoMagico;
typedef struct { float x; float alturaAtual; float alturaMax; bool ativa; } ArvoreProtetora;

// [CG_UFRRJ: Expansao de Entidade - Flags de Agonia e Temporizacao de Espreita]
typedef struct { 
    float x, y, largura, altura; 
    bool vivo; 
    float saude; 
    bool hipnotizado; 
    float temporizadorEspera; // 6.0s de transe inicial na floresta
    bool desintegrando;       // Flag de morte cinematica
    float temporizadorMorte;  // 1.8s de agonia antes do drop do anel
} LobisomemBoss;

// --- INSTÂNCIAS GLOBAIS ---
Jogador conde = { 100.0f, 150.0f, 30.0f, 50.0f, 0.0f, 0.0f, 6.0f, false, 100.0f, 0, 0.0f, 0.0f };
struct { float x, velocidade; } sol = { -120.0f, 0.55f }; 

const char* causaMorteAtual = "CONSUMIDO PELAS CINZAS!";
bool cameraApresentando = true;
float cameraIntroX = 100.0f;
bool cameraIntroIndo = true;

char nomeJogador[16] = "";
int tamanhoNome = 0;
bool salvoComSucesso = false;
char linhasHistorico[10][100];
int totalLinhasHistorico = 0;

Plataforma cenario[NUM_PLATAFORMAS] = {
    { 0.0f,    0.0f,   800.0f,  50.0f }, { 800.0f, -20.0f,  600.0f,  70.0f }, 
    { 1400.0f, 0.0f,   500.0f,  80.0f }, { 2050.0f, 0.0f,   800.0f,  50.0f }, 
    { 2850.0f, 0.0f,   400.0f,  90.0f }, { 3400.0f, 0.0f,   600.0f,  70.0f }, 
    { 4000.0f,-10.0f,  400.0f,  60.0f }, { 4400.0f, 0.0f,   1200.0f, 70.0f }  
};

ObjetoDano alhos[NUM_ALHOS] = {
    { 1100.0f, 50.0f, 22.0f, 22.0f, true }, { 2500.0f, 50.0f, 22.0f, 22.0f, true }, { 3700.0f, 70.0f, 22.0f, 22.0f, true }  
};

// Paladino atualizado com subsistema de desintegração lenta
struct { 
    float x, y, largura, altura; 
    bool vivo; 
    float temporizadorTiro; 
    bool desintegrando; 
    float temporizadorMorte; 
} paladino = { 5000.0f, 70.0f, 40.0f, 80.0f, true, 0.0f, false, 1.8f };

Estaca estaca = { 0.0f, 0.0f, 30.0f, 8.0f, false };
Trofeu anel   = { 0.0f, 0.0f, 25.0f, 25.0f, false };

Plataforma cenarioFase2[8] = {
    { 0.0f,    0.0f,   800.0f,  50.0f }, { 800.0f, -10.0f,  600.0f,  60.0f }, 
    { 1400.0f, 0.0f,   400.0f,  50.0f }, { 1800.0f, 0.0f,   1200.0f, 50.0f }, 
    { 3000.0f, 0.0f,   1000.0f, 50.0f }, { 4000.0f, 0.0f,   800.0f,  50.0f }, 
    { 4800.0f, 0.0f,   1500.0f, 50.0f }, { 6300.0f, 0.0f,   500.0f,  50.0f }  
};

ObjetoDano crucifixos[3] = {
    { 1100.0f, 50.0f, 20.0f, 30.0f, true }, { 3450.0f, 50.0f, 20.0f, 30.0f, true }, { 4100.0f, 50.0f, 20.0f, 30.0f, true }  
};

PoMagico posMagicos[3];
ArvoreProtetora arvore = { 0.0f, 0.0f, 220.0f, false };

LobisomemBoss lobisomem = { 5200.0f, 50.0f, 50.0f, 80.0f, true, 100.0f, false, 6.0f, false, 1.8f }; 
Trofeu anel2            = { 0.0f, 0.0f, 25.0f, 25.0f, false };

bool checarColisaoAABB(float x1, float y1, float w1, float h1, float x2, float y2, float w2, float h2) {
    return (x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2);
}

void desenharTexto(float x, float y, void* fonte, const char* texto) {
    glRasterPos2f(x, y);
    for (const char* c = texto; *c != '\0'; c++) glutBitmapCharacter(fonte, *c);
}

void desenharTextoCentralizado(float y, void* fonte, const char* texto) {
    int larguraTexto = glutBitmapLength(fonte, (const unsigned char*)texto);
    desenharTexto((TELA_LARGURA - larguraTexto) / 2.0f, y, fonte, texto);
}

void carregarHistorico() {
    totalLinhasHistorico = 0; FILE* arquivo = fopen("ranking.txt", "r"); if (!arquivo) return;
    while (fgets(linhasHistorico[totalLinhasHistorico], 100, arquivo) != NULL && totalLinhasHistorico < 10) { linhasHistorico[totalLinhasHistorico][strcspn(linhasHistorico[totalLinhasHistorico], "\n")] = 0; totalLinhasHistorico++; }
    fclose(arquivo);
}

void resetarJogo() {
    conde.x = 100.0f; conde.y = 150.0f; conde.velX = 0.0f; conde.velY = 0.0f; 
    conde.energia_vital = 100.0f; conde.tempoPiscar = 0.0f; conde.temporizadorParry = 0.0f;
    sol.x = -120.0f; 
    
    if (faseAtualRoteada == ESTADO_FASE1) {
        sol.velocidade = 0.55f; 
        paladino.vivo = true; paladino.temporizadorTiro = 0.0f; 
        paladino.desintegrando = false; paladino.temporizadorMorte = 1.8f;
        anel.visivel = false; estaca.viva = false;
        for(int i=0; i<NUM_ALHOS; i++) alhos[i].ativo = true;
    } else {
        sol.velocidade = 3.2f; 
        lobisomem.x = 5200.0f; lobisomem.vivo = true; lobisomem.saude = 100.0f; 
        lobisomem.hipnotizado = false; lobisomem.temporizadorEspera = 6.0f;
        lobisomem.desintegrando = false; lobisomem.temporizadorMorte = 1.8f;
        anel2.visivel = false;
        for(int i=0; i<3; i++) crucifixos[i].ativo = true;

        posMagicos[0].x = 4600.0f; posMagicos[0].y = 50.0f; posMagicos[0].ativo = true;
        posMagicos[1].x = 4850.0f; posMagicos[1].y = 50.0f; posMagicos[1].ativo = true;
        posMagicos[2].x = 5080.0f; posMagicos[2].y = 50.0f; posMagicos[2].ativo = true;
        arvore.alturaAtual = 0.0f; arvore.alturaMax = 220.0f; arvore.ativa = false;
    }

    cameraApresentando = true; cameraIntroX = conde.x; cameraIntroIndo = true;
}

void desenharMenu() {
    glClearColor(0.05f, 0.05f, 0.15f, 1.0f); glClear(GL_COLOR_BUFFER_BIT);
    glColor3f(0.9f, 0.8f, 0.1f); desenharTextoCentralizado(500.0f, GLUT_BITMAP_TIMES_ROMAN_24, "DESPERTAR DAS SOMBRAS: A FUGA DO CONDE");
    glColor3f(0.5f, 0.5f, 0.6f); desenharTextoCentralizado(460.0f, GLUT_BITMAP_HELVETICA_12, "Sistema de Modulos de Defesa (PT-BR)");

    glColor3f(0.2f, 0.6f, 0.2f); glBegin(GL_QUADS); glVertex2f(BTN_X1, BTN_INICIAR_Y1); glVertex2f(BTN_X2, BTN_INICIAR_Y1); glVertex2f(BTN_X2, BTN_INICIAR_Y2); glVertex2f(BTN_X1, BTN_INICIAR_Y2); glEnd();
    glColor3f(1.0f, 1.0f, 1.0f); desenharTextoCentralizado(368.0f, GLUT_BITMAP_HELVETICA_18, "INICIAR JOGO");

    glColor3f(0.2f, 0.4f, 0.6f); glBegin(GL_QUADS); glVertex2f(BTN_X1, BTN_HIST_Y1); glVertex2f(BTN_X2, BTN_HIST_Y1); glVertex2f(BTN_X2, BTN_HIST_Y2); glVertex2f(BTN_X1, BTN_HIST_Y2); glEnd();
    glColor3f(1.0f, 1.0f, 1.0f); desenharTextoCentralizado(288.0f, GLUT_BITMAP_HELVETICA_18, "HISTORICO DE RECORDES");

    glColor3f(0.6f, 0.2f, 0.2f); glBegin(GL_QUADS); glVertex2f(BTN_X1, BTN_SAIR_Y1); glVertex2f(BTN_X2, BTN_SAIR_Y1); glVertex2f(BTN_X2, BTN_SAIR_Y2); glVertex2f(BTN_X1, BTN_SAIR_Y2); glEnd();
    glColor3f(1.0f, 1.0f, 1.0f); desenharTextoCentralizado(208.0f, GLUT_BITMAP_HELVETICA_18, "SAIR DO JOGO");
}

void desenharHUD(const char* textoMissao) {
    glColor3f(0.15f, 0.15f, 0.15f); glBegin(GL_QUADS); glVertex2f(20, 550); glVertex2f(220, 550); glVertex2f(220, 580); glVertex2f(20, 580); glEnd();
    glColor3f(0.9f, 0.1f, 0.1f); glBegin(GL_QUADS); glVertex2f(20, 550); glVertex2f(20 + (conde.energia_vital * 2.0f), 550); glVertex2f(20 + (conde.energia_vital * 2.0f), 580); glVertex2f(20, 580); glEnd();
    
    glColor3f(1.0f, 1.0f, 1.0f); char textoHP[32]; sprintf(textoHP, "%d%%", (int)conde.energia_vital);
    desenharTexto(105, 560, GLUT_BITMAP_HELVETICA_12, textoHP);

    desenharTexto(240, 562, GLUT_BITMAP_HELVETICA_18, textoMissao);
    
    glColor3f(0.65f, 0.65f, 0.65f); 
    if (estadoAtual == ESTADO_FASE1)      desenharTexto(240, 542, GLUT_BITMAP_HELVETICA_12, "[P] Pausar o Jogo");
    else if (estadoAtual == ESTADO_FASE2) desenharTexto(240, 542, GLUT_BITMAP_HELVETICA_12, "[P] Pausar | [Z] Capa de Hipnose (Ataque no Lobo)");

    if (cameraApresentando) { glColor3f(1.0f, 0.85f, 0.1f); desenharTextoCentralizado(480.0f, GLUT_BITMAP_TIMES_ROMAN_24, ">>> VOO DE RECONHECIMENTO... AGUARDE! <<<"); }
}

void desenharFase1() {
    glClearColor(0.08f, 0.08f, 0.12f, 1.0f); glClear(GL_COLOR_BUFFER_BIT); glPushMatrix();
    float alvoCameraX = cameraApresentando ? cameraIntroX : conde.x; glTranslatef(-alvoCameraX + (TELA_LARGURA / 3.0f), 0.0f, 0.0f);

    glColor3f(0.28f, 0.28f, 0.32f); for (int i = 0; i < NUM_PLATAFORMAS; i++) { glBegin(GL_QUADS); glVertex2f(cenario[i].x, cenario[i].y); glVertex2f(cenario[i].x + cenario[i].largura, cenario[i].y); glVertex2f(cenario[i].x + cenario[i].largura, cenario[i].y + cenario[i].altura); glVertex2f(cenario[i].x, cenario[i].y + cenario[i].altura); glEnd(); }
    glColor3f(0.95f, 0.95f, 0.95f); for (int i = 0; i < NUM_ALHOS; i++) { if (alhos[i].ativo) { glBegin(GL_TRIANGLES); glVertex2f(alhos[i].x, alhos[i].y); glVertex2f(alhos[i].x + alhos[i].largura, alhos[i].y); glVertex2f(alhos[i].x + (alhos[i].largura / 2.0f), alhos[i].y + (alhos[i].altura*1.6f)); glEnd(); } }

    if (paladino.vivo) { 
        if(paladino.desintegrando) glColor3f(0.4f, 0.5f, 0.8f); // Palido desbotando
        else glColor3f(0.2f, 0.4f, 0.9f); 

        glBegin(GL_QUADS); glVertex2f(paladino.x, paladino.y); glVertex2f(paladino.x + paladino.largura, paladino.y); glVertex2f(paladino.x + paladino.largura, paladino.y + paladino.altura); glVertex2f(paladino.x, paladino.y + paladino.altura); glEnd(); 

        if(paladino.desintegrando) { glColor3f(1.0f, 1.0f, 1.0f); desenharTexto(paladino.x - 25, paladino.y + paladino.altura + 10, GLUT_BITMAP_HELVETICA_12, "DESINTEGRANDO..."); }
    }
    
    if (estaca.viva) { glColor3f(0.6f, 0.3f, 0.1f); glBegin(GL_QUADS); glVertex2f(estaca.x, estaca.y); glVertex2f(estaca.x + estaca.largura, estaca.y); glVertex2f(estaca.x + estaca.largura, estaca.y + estaca.altura); glVertex2f(estaca.x, estaca.y + estaca.altura); glEnd(); }
    if (anel.visivel) { glColor3f(1.0f, 0.84f, 0.0f); glBegin(GL_QUADS); glVertex2f(anel.x, anel.y); glVertex2f(anel.x + anel.largura, anel.y); glVertex2f(anel.x + anel.largura, anel.y + anel.altura); glVertex2f(anel.x, anel.y + anel.altura); glEnd(); }

    if (conde.tempoPiscar > 0.0f) glColor3f(1.0f, 1.0f, 1.0f); else glColor3f(0.8f, 0.1f, 0.1f);                          
    glBegin(GL_QUADS); glVertex2f(conde.x, conde.y); glVertex2f(conde.x + conde.largura, conde.y); glVertex2f(conde.x + conde.largura, conde.y + conde.altura); glVertex2f(conde.x, conde.y + conde.altura); glEnd();

    glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); glColor4f(1.0f, 0.6f, 0.0f, 0.35f); glBegin(GL_QUADS); glVertex2f(sol.x - 1200.0f, 0.0f); glVertex2f(sol.x, 0.0f); glVertex2f(sol.x, TELA_ALTURA); glVertex2f(sol.x - 1200.0f, TELA_ALTURA); glEnd(); glDisable(GL_BLEND);
    glPopMatrix(); desenharHUD((conde.fragmentos_anel > 0) ? "ANEL: 1/3" : "ANEL: 0/3");
}

void desenharFase2() {
    glClearColor(0.06f, 0.08f, 0.05f, 1.0f); glClear(GL_COLOR_BUFFER_BIT); glPushMatrix();
    float alvoCameraX = cameraApresentando ? cameraIntroX : conde.x; glTranslatef(-alvoCameraX + (TELA_LARGURA / 3.0f), 0.0f, 0.0f);

    glColor3f(0.32f, 0.21f, 0.14f); for (int i = 0; i < 8; i++) { glBegin(GL_QUADS); glVertex2f(cenarioFase2[i].x, cenarioFase2[i].y); glVertex2f(cenarioFase2[i].x + cenarioFase2[i].largura, cenarioFase2[i].y); glVertex2f(cenarioFase2[i].x + cenarioFase2[i].largura, cenarioFase2[i].y + cenarioFase2[i].altura); glVertex2f(cenarioFase2[i].x, cenarioFase2[i].y + cenarioFase2[i].altura); glEnd(); }

    glColor3f(1.0f, 0.85f, 0.1f);
    for (int i = 0; i < 3; i++) { if (crucifixos[i].ativo) { float cx = crucifixos[i].x; float cy = crucifixos[i].y; float cw = crucifixos[i].largura; float ch = crucifixos[i].altura; glBegin(GL_QUADS); glVertex2f(cx + cw*0.35f, cy); glVertex2f(cx + cw*0.65f, cy); glVertex2f(cx + cw*0.65f, cy + ch); glVertex2f(cx + cw*0.35f, cy + ch); glVertex2f(cx, cy + ch*0.5f); glVertex2f(cx + cw, cy + ch*0.5f); glVertex2f(cx + cw, cy + ch*0.75f); glVertex2f(cx, cy + ch*0.75f); glEnd(); } }

    for(int i=0; i<3; i++) { if(posMagicos[i].ativo) { glColor3f(0.3f, 1.0f, 0.4f); glBegin(GL_QUADS); glVertex2f(posMagicos[i].x, posMagicos[i].y); glVertex2f(posMagicos[i].x+16.0f, posMagicos[i].y); glVertex2f(posMagicos[i].x+16.0f, posMagicos[i].y+16.0f); glVertex2f(posMagicos[i].x, posMagicos[i].y+16.0f); glEnd(); } }

    if(arvore.ativa) {
        float baseY = 50.0f; float largTronco = 12.0f; float largCopa = arvore.alturaAtual * 0.6f; float alturaTronco = arvore.alturaAtual * 0.45f; float alturaFolhas = arvore.alturaAtual * 0.55f;
        glColor3f(0.42f, 0.24f, 0.08f); glBegin(GL_QUADS); glVertex2f(arvore.x, baseY); glVertex2f(arvore.x+largTronco, baseY); glVertex2f(arvore.x+largTronco, baseY+alturaTronco); glVertex2f(arvore.x, baseY+alturaTronco); glEnd();
        glColor3f(0.1f, 0.5f, 0.12f); float copaX = arvore.x + largTronco/2.0f - largCopa/2.0f; glBegin(GL_QUADS); glVertex2f(copaX, baseY+alturaTronco); glVertex2f(copaX+largCopa, baseY+alturaTronco); glVertex2f(copaX+largCopa, baseY+alturaTronco+alturaFolhas); glVertex2f(copaX, baseY+alturaTronco+alturaFolhas); glEnd();
        float compSombra = arvore.alturaAtual * 2.2f; glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); glColor4f(0.0f, 0.0f, 0.0f, 0.55f); glBegin(GL_QUADS); glVertex2f(arvore.x+largTronco, baseY); glVertex2f(arvore.x+largTronco+compSombra, baseY); glVertex2f(arvore.x+largTronco+compSombra, baseY+arvore.alturaAtual); glVertex2f(arvore.x+largTronco, baseY+arvore.alturaAtual); glEnd(); glDisable(GL_BLEND);
    }

    if (lobisomem.vivo) {
        if(lobisomem.desintegrando) glColor3f(0.6f, 0.2f, 0.6f); // Roxo moribundo
        else if (!lobisomem.hipnotizado) glColor3f(0.4f, 0.2f, 0.1f); 
        else glColor3f(0.8f, 0.1f, 0.8f);

        glBegin(GL_QUADS); glVertex2f(lobisomem.x, lobisomem.y); glVertex2f(lobisomem.x + lobisomem.largura, lobisomem.y); glVertex2f(lobisomem.x + lobisomem.largura, lobisomem.y + lobisomem.altura); glVertex2f(lobisomem.x, lobisomem.y + lobisomem.altura); glEnd();

        if (lobisomem.desintegrando) {
            glColor3f(1.0f, 1.0f, 1.0f); desenharTexto(lobisomem.x - 20, lobisomem.y + lobisomem.altura + 15, GLUT_BITMAP_HELVETICA_12, "SUCUMBINDO...");
        } else if (!lobisomem.hipnotizado) { 
            // FEEDBACK VISUAL DOS 6 SEGUNDOS DE ESPERA
            if(lobisomem.temporizadorEspera > 0.0f) {
                char txtFarejo[64]; sprintf(txtFarejo, "ESPREITANDO... (%.1fs)", lobisomem.temporizadorEspera);
                glColor3f(1.0f, 0.6f, 0.1f); desenharTexto(lobisomem.x - 40, lobisomem.y + lobisomem.altura + 15, GLUT_BITMAP_HELVETICA_12, txtFarejo);
            } else {
                char textoLobo[64]; sprintf(textoLobo, "LOBO HP: %d%% | ENCOSTE SEGURANDO [Z]", (int)lobisomem.saude);
                glColor3f(1.0f, 0.3f, 0.3f); desenharTexto(lobisomem.x - 70, lobisomem.y + lobisomem.altura + 15, GLUT_BITMAP_HELVETICA_12, textoLobo); 
            }
        } else { glColor3f(0.2f, 1.0f, 0.2f); desenharTexto(lobisomem.x - 25, lobisomem.y + lobisomem.altura + 15, GLUT_BITMAP_HELVETICA_12, "HIPNOTIZADO! MORDA!"); }
    }

    if (anel2.visivel) { glColor3f(1.0f, 0.84f, 0.0f); glBegin(GL_QUADS); glVertex2f(anel2.x, anel2.y); glVertex2f(anel2.x + anel2.largura, anel2.y); glVertex2f(anel2.x + anel2.largura, anel2.y + anel2.altura); glVertex2f(anel2.x, anel2.y + anel2.altura); glEnd(); }

    if (conde.temporizadorParry > 0.0f) glColor3f(0.0f, 0.8f, 1.0f); else if (conde.tempoPiscar > 0.0f) glColor3f(1.0f, 1.0f, 1.0f); else glColor3f(0.8f, 0.1f, 0.1f);                          
    glBegin(GL_QUADS); glVertex2f(conde.x, conde.y); glVertex2f(conde.x + conde.largura, conde.y); glVertex2f(conde.x + conde.largura, conde.y + conde.altura); glVertex2f(conde.x, conde.y + conde.altura); glEnd();

    glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); glColor4f(1.0f, 0.6f, 0.0f, 0.35f); glBegin(GL_QUADS); glVertex2f(sol.x - 1200.0f, 0.0f); glVertex2f(sol.x, 0.0f); glVertex2f(sol.x, TELA_ALTURA); glVertex2f(sol.x - 1200.0f, TELA_ALTURA); glEnd(); glDisable(GL_BLEND);
    glPopMatrix(); desenharHUD((conde.fragmentos_anel > 1) ? "ANEL: 2/3" : "ANEL: 1/3 (Fase 2)");
}

void desenharPause() { if (faseAtualRoteada == ESTADO_FASE1) desenharFase1(); else desenharFase2(); glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); glColor4f(0.0f, 0.0f, 0.0f, 0.75f); glBegin(GL_QUADS); glVertex2f(0,0); glVertex2f(TELA_LARGURA,0); glVertex2f(TELA_LARGURA,TELA_ALTURA); glVertex2f(0,TELA_ALTURA); glEnd(); glDisable(GL_BLEND); glColor3f(1.0f, 0.8f, 0.1f); desenharTextoCentralizado(380.0f, GLUT_BITMAP_TIMES_ROMAN_24, "JOGO PAUSADO"); glColor3f(1.0f, 1.0f, 1.0f); desenharTextoCentralizado(300.0f, GLUT_BITMAP_HELVETICA_18, "[P] Continuar a Corrida"); desenharTextoCentralizado(260.0f, GLUT_BITMAP_HELVETICA_18, "[S] Salvar Progresso no Disco"); desenharTextoCentralizado(220.0f, GLUT_BITMAP_HELVETICA_18, "[M] Abandonar para o Menu"); }
void desenharSalvarRecorde() { glClearColor(0.05f, 0.1f, 0.05f, 1.0f); glClear(GL_COLOR_BUFFER_BIT); glColor3f(0.4f, 1.0f, 0.4f); desenharTextoCentralizado(480.0f, GLUT_BITMAP_TIMES_ROMAN_24, "TERMINAL DE GRAVACAO DE DADOS"); glColor3f(0.8f, 0.8f, 0.8f); desenharTextoCentralizado(420.0f, GLUT_BITMAP_HELVETICA_12, "Digite seu Nome (A-Z) e pressione [ENTER]:"); glColor3f(0.1f, 0.2f, 0.1f); glBegin(GL_QUADS); glVertex2f(250, 320); glVertex2f(550, 320); glVertex2f(550, 370); glVertex2f(250, 370); glEnd(); glColor3f(0.5f, 1.0f, 0.5f); glBegin(GL_LINE_LOOP); glVertex2f(250, 320); glVertex2f(550, 320); glVertex2f(550, 370); glVertex2f(250, 370); glEnd(); glColor3f(1.0f, 1.0f, 1.0f); char textoCaixa[32]; sprintf(textoCaixa, "%s_", nomeJogador); desenharTextoCentralizado(338.0f, GLUT_BITMAP_HELVETICA_18, textoCaixa); if (salvoComSucesso) { glColor3f(1.0f, 0.9f, 0.1f); desenharTextoCentralizado(240.0f, GLUT_BITMAP_HELVETICA_18, ">>> DADOS GRAVADOS EM ranking.txt! <<<"); glColor3f(0.7f, 0.7f, 0.7f); desenharTextoCentralizado(200.0f, GLUT_BITMAP_HELVETICA_12, "Pressione qualquer tecla para voltar ao Menu"); } else { glColor3f(0.5f, 0.5f, 0.5f); desenharTextoCentralizado(240.0f, GLUT_BITMAP_HELVETICA_12, "[ESC] para cancelar"); } }
void desenharHistorico() { glClearColor(0.05f, 0.05f, 0.12f, 1.0f); glClear(GL_COLOR_BUFFER_BIT); glColor3f(1.0f, 0.7f, 0.1f); desenharTextoCentralizado(520.0f, GLUT_BITMAP_TIMES_ROMAN_24, "LIVRO DOS RECORDES (ranking.txt)"); glColor3f(0.8f, 0.8f, 0.8f); if (totalLinhasHistorico == 0) desenharTextoCentralizado(350.0f, GLUT_BITMAP_HELVETICA_18, "Nenhum registro encontrado no disco."); else for (int i = 0; i < totalLinhasHistorico; i++) { glRasterPos2f(100.0f, 450.0f - (i * 30.0f)); for (const char* c = linhasHistorico[i]; *c != '\0'; c++) glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, *c); } glColor3f(0.5f, 1.0f, 0.5f); desenharTextoCentralizado(80.0f, GLUT_BITMAP_HELVETICA_18, "Pressione [M] para voltar ao Menu"); }
void desenharTelasFinais(const char* titulo, const char* subtitulo) { glClearColor(0.1f, 0.0f, 0.0f, 1.0f); glClear(GL_COLOR_BUFFER_BIT); glColor3f(1.0f, 0.8f, 0.2f); desenharTextoCentralizado(380.0f, GLUT_BITMAP_TIMES_ROMAN_24, titulo); glColor3f(0.8f, 0.8f, 0.8f); desenharTextoCentralizado(320.0f, GLUT_BITMAP_HELVETICA_12, subtitulo); if (estadoAtual == ESTADO_VITORIA) { glColor3f(0.2f, 1.0f, 0.2f); desenharTextoCentralizado(260.0f, GLUT_BITMAP_HELVETICA_12, "Pressione [C] para Avancar para a Proxima Fase!"); } glColor3f(0.4f, 1.0f, 0.4f); desenharTextoCentralizado(220.0f, GLUT_BITMAP_HELVETICA_12, "Pressione [S] para Salvar sua Pontuacao no Ranking"); }

// =====================================================================
// MOTORES DE FÍSICA E COLISÃO (MÁQUINA TEMPORIZADA)
// =====================================================================

void atualizarFisica(int valor) {
    if(conde.temporizadorParry > 0.0f) conde.temporizadorParry -= (1.0f / 60.0f);

    // =================================================================
    // FÍSICA DA FASE 1
    // =================================================================
    if (estadoAtual == ESTADO_FASE1) {
        if (cameraApresentando) { if (cameraIntroIndo) { cameraIntroX += 14.0f; if (cameraIntroX >= paladino.x) cameraIntroIndo = false; } else { cameraIntroX -= 20.0f; if (cameraIntroX <= conde.x) { cameraIntroX = conde.x; cameraApresentando = false; } } glutPostRedisplay(); glutTimerFunc(16, atualizarFisica, 0); return; }

        sol.x += sol.velocidade; if (conde.tempoPiscar > 0.0f) conde.tempoPiscar -= 1.0f;
        conde.velY -= 0.65f; conde.y += conde.velY; conde.noChao = false;

        for (int i = 0; i < NUM_PLATAFORMAS; i++) { if (checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, cenario[i].x, cenario[i].y, cenario[i].largura, cenario[i].altura)) { if (conde.velY < 0.0f && (conde.y - conde.velY) >= (cenario[i].y + cenario[i].altura - 12.0f)) { conde.y = cenario[i].y + cenario[i].altura; conde.velY = 0.0f; conde.noChao = true; } } }
        conde.x += conde.velX;
        for (int i = 0; i < NUM_PLATAFORMAS; i++) { if (checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, cenario[i].x, cenario[i].y, cenario[i].largura, cenario[i].altura)) { if (conde.velX > 0.0f) conde.x = cenario[i].x - conde.largura; else if (conde.velX < 0.0f) conde.x = cenario[i].x + cenario[i].largura; } }

        for(int i=0; i<NUM_ALHOS; i++) { if(alhos[i].ativo && checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, alhos[i].x, alhos[i].y, alhos[i].largura, alhos[i].altura)) { conde.energia_vital -= 10.0f; alhos[i].ativo = false; conde.tempoPiscar = 15.0f; if(conde.energia_vital <= 0.0f) { causaMorteAtual = "SUCUMBIU AO ALHO!"; estadoAtual = ESTADO_GAME_OVER; } } }
        
        // --- LOGICA DE MORTE LENTA DO PALADINO ---
        if(paladino.vivo) {
            if(!paladino.desintegrando) {
                if(conde.x >= 4300.0f) { paladino.temporizadorTiro += (1.0f / 60.0f); if(paladino.temporizadorTiro >= 2.5f) { estaca.x = paladino.x; estaca.y = paladino.y + 30.0f; estaca.viva = true; paladino.temporizadorTiro = 0.0f; } }
                // Tocou nele vivo -> Congela e inicia desintegração!
                if(checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, paladino.x, paladino.y, paladino.largura, paladino.altura)) {
                    paladino.desintegrando = true;
                    sol.velocidade = 0.0f; 
                }
            } else {
                // Em processo de morte (1.8s)
                paladino.temporizadorMorte -= (1.0f / 60.0f);
                if(paladino.temporizadorMorte <= 0.0f) {
                    paladino.vivo = false;
                    anel.visivel = true; anel.x = paladino.x + 50.0f; anel.y = 70.0f;
                }
            }
        }

        if(estaca.viva) { estaca.x -= 8.0f; if(checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, estaca.x, estaca.y, estaca.largura, estaca.altura)) { conde.energia_vital -= 10.0f; estaca.viva = false; conde.tempoPiscar = 15.0f; if(conde.energia_vital <= 0.0f) { causaMorteAtual = "TRESPASSADO PELA ESTACA!"; estadoAtual = ESTADO_GAME_OVER; } } if(estaca.x < conde.x - 500.0f) estaca.viva = false; }
        if(anel.visivel && checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, anel.x, anel.y, anel.largura, anel.altura)) { conde.fragmentos_anel = 1; anel.visivel = false; causaMorteAtual = "VITORIA DA FASE 1!"; faseAtualRoteada = ESTADO_FASE2; estadoAtual = ESTADO_VITORIA; }

        if ((conde.x + conde.largura / 2.0f) < sol.x) { conde.energia_vital -= 0.4f; conde.tempoPiscar = 2.0f; if (conde.energia_vital <= 0.0f) { causaMorteAtual = "VIROU CINZAS NO SOL!"; estadoAtual = ESTADO_GAME_OVER; } }
        if (conde.y < -100.0f) { causaMorteAtual = "DESPENCOU NO ABISMO!"; estadoAtual = ESTADO_GAME_OVER; }
    }

    // =================================================================
    // FÍSICA DA FASE 2 (Com arvore crescendo e Lobo espreitando)
    // =================================================================
    else if (estadoAtual == ESTADO_FASE2) {
        if (cameraApresentando) { if (cameraIntroIndo) { cameraIntroX += 14.0f; if (cameraIntroX >= lobisomem.x) cameraIntroIndo = false; } else { cameraIntroX -= 20.0f; if (cameraIntroX <= conde.x) { cameraIntroX = conde.x; cameraApresentando = false; } } glutPostRedisplay(); glutTimerFunc(16, atualizarFisica, 0); return; }

        sol.x += sol.velocidade; if (conde.tempoPiscar > 0.0f) conde.tempoPiscar -= 1.0f;

        conde.x += conde.velX;
        for (int i = 0; i < 8; i++) { if (checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, cenarioFase2[i].x, cenarioFase2[i].y, cenarioFase2[i].largura, cenarioFase2[i].altura)) { if (conde.velX > 0.0f) conde.x = cenarioFase2[i].x - conde.largura; else if (conde.velX < 0.0f) conde.x = cenarioFase2[i].x + cenarioFase2[i].largura; } }

        for(int i=0; i<3; i++) {
            if(posMagicos[i].ativo && checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, posMagicos[i].x, posMagicos[i].y, 16.0f, 16.0f)) {
                posMagicos[i].ativo = false; arvore.x = conde.x - 30.0f; arvore.alturaAtual = 8.0f; arvore.ativa = true;
            }
        }
        if(arvore.ativa && arvore.alturaAtual < arvore.alturaMax) arvore.alturaAtual += 0.7f;

        conde.velY -= 0.65f; conde.y += conde.velY; conde.noChao = false;
        for (int i = 0; i < 8; i++) { if (checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, cenarioFase2[i].x, cenarioFase2[i].y, cenarioFase2[i].largura, cenarioFase2[i].altura)) { if (conde.velY < 0.0f && (conde.y - conde.velY) >= (cenarioFase2[i].y + cenarioFase2[i].altura - 12.0f)) { conde.y = cenarioFase2[i].y + cenarioFase2[i].altura; conde.velY = 0.0f; conde.noChao = true; } } }

        bool imuneAoSol = false;
        if(arvore.ativa) { float compSombra = arvore.alturaAtual * 2.2f; if(conde.x >= arvore.x && conde.x <= (arvore.x + 12.0f + compSombra)) imuneAoSol = true; }
        if (!imuneAoSol && (conde.x + conde.largura / 2.0f) < sol.x) { conde.energia_vital -= 0.4f; conde.tempoPiscar = 2.0f; if (conde.energia_vital <= 0.0f) { causaMorteAtual = "VIROU CINZAS NO SOL!"; estadoAtual = ESTADO_GAME_OVER; } }

        for (int i = 0; i < 3; i++) { if (crucifixos[i].ativo && checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, crucifixos[i].x, crucifixos[i].y, crucifixos[i].largura, crucifixos[i].altura)) { conde.energia_vital -= 10.0f; conde.tempoPiscar = 15.0f; crucifixos[i].ativo = false; if (conde.energia_vital <= 0.0f) { causaMorteAtual = "QUEIMADO PELO CRUCIFIXO!"; estadoAtual = ESTADO_GAME_OVER; } } }

        // --- SUBSISTEMA DO LOBISOMEM COM ESPREITA DE 6s E MORTE LENTA ---
        if (lobisomem.vivo && conde.x >= 4500.0f) {
            if (!lobisomem.desintegrando) {
                if (!lobisomem.hipnotizado) {
                    
                    // 1. CONTAGEM REGRESSIVA DOS 6 SEGUNDOS DE ESPREITA
                    if(lobisomem.temporizadorEspera > 0.0f) {
                        lobisomem.temporizadorEspera -= (1.0f / 60.0f);
                    } else {
                        // Fera liberada para caçar!
                        if (lobisomem.x > conde.x) lobisomem.x -= 3.8f; else if (lobisomem.x < conde.x) lobisomem.x += 3.8f;

                        if (checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, lobisomem.x, lobisomem.y, lobisomem.largura, lobisomem.altura)) {
                            if (conde.temporizadorParry > 0.0f) {
                                lobisomem.saude -= 25.0f; lobisomem.x += 140.0f; conde.temporizadorParry = 0.0f;
                                if (lobisomem.saude <= 0.0f) { lobisomem.saude = 0.0f; lobisomem.hipnotizado = true; }
                            } else { conde.energia_vital -= 15.0f; conde.tempoPiscar = 15.0f; conde.x -= 50.0f; conde.velY = 4.0f; if (conde.energia_vital <= 0.0f) { causaMorteAtual = "DESPEDAÇADO PELO LOBISOMEM!"; estadoAtual = ESTADO_GAME_OVER; } }
                        }
                    }
                } else {
                    // Lobo hipnotizado de joelhos! Conde morde para desintegrar
                    if (checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, lobisomem.x, lobisomem.y, lobisomem.largura, lobisomem.altura)) {
                        lobisomem.desintegrando = true; // Inicia a morte cinematica
                        conde.energia_vital = 100.0f; 
                        conde.x -= 75.0f; 
                        sol.velocidade = 0.0f;
                    }
                }
            } else {
                // 2. PROCESSO DE MORTE LENTA DO LOBO (1.8s)
                lobisomem.temporizadorMorte -= (1.0f / 60.0f);
                if (lobisomem.temporizadorMorte <= 0.0f) {
                    lobisomem.vivo = false;
                    anel2.visivel = true; 
                    anel2.x = lobisomem.x; anel2.y = 50.0f;
                }
            }
        }

        if (anel2.visivel && checarColisaoAABB(conde.x, conde.y, conde.largura, conde.altura, anel2.x, anel2.y, anel2.largura, anel2.altura)) { conde.fragmentos_anel = 2; anel2.visivel = false; causaMorteAtual = "VITORIA DA FASE 2!"; estadoAtual = ESTADO_VITORIA; }
        if (conde.y < -100.0f) { causaMorteAtual = "DESPENCOU NO ABISMO!"; estadoAtual = ESTADO_GAME_OVER; }
    }

    glutPostRedisplay();
    glutTimerFunc(16, atualizarFisica, 0);
}

void gerenciarMouse(int botao, int estado, int x, int y_glut) { if (estadoAtual == ESTADO_MENU && botao == GLUT_LEFT_BUTTON && estado == GLUT_DOWN) { float y_opengl = TELA_ALTURA - y_glut; if (x >= BTN_X1 && x <= BTN_X2) { if (y_opengl >= BTN_INICIAR_Y1 && y_opengl <= BTN_INICIAR_Y2) { faseAtualRoteada = ESTADO_FASE1; resetarJogo(); estadoAtual = ESTADO_FASE1; } else if (y_opengl >= BTN_HIST_Y1 && y_opengl <= BTN_HIST_Y2) { carregarHistorico(); estadoAtual = ESTADO_HISTORICO; } else if (y_opengl >= BTN_SAIR_Y1 && y_opengl <= BTN_SAIR_Y2) exit(0); } } }
void soltarTeclas(int tecla, int x, int y) { if (tecla == GLUT_KEY_LEFT || tecla == GLUT_KEY_RIGHT) conde.velX = 0.0f; }
void pressionarTeclasEspeciais(int tecla, int x, int y) { if ((estadoAtual == ESTADO_FASE1 || estadoAtual == ESTADO_FASE2) && !cameraApresentando) { if (tecla == GLUT_KEY_RIGHT) conde.velX = conde.velocidade; if (tecla == GLUT_KEY_LEFT) conde.velX = -conde.velocidade; if (tecla == GLUT_KEY_UP && conde.noChao) { conde.velY = 13.5f; conde.noChao = false; } } }

void tecladoNormal(unsigned char tecla, int x, int y) {
    if ((estadoAtual == ESTADO_FASE1 || estadoAtual == ESTADO_FASE2) && !cameraApresentando) {
        if (tecla == 'p' || tecla == 'P') { estadoAtual = ESTADO_PAUSE; return; }
        if (tecla == 'z' || tecla == 'Z') { conde.temporizadorParry = 0.8f; return; } 
    }
    
    if (estadoAtual == ESTADO_PAUSE) { if (tecla == 'p' || tecla == 'P') { estadoAtual = faseAtualRoteada; return; } if (tecla == 'm' || tecla == 'M') { estadoAtual = ESTADO_MENU; return; } if (tecla == 's' || tecla == 'S') { salvoComSucesso = false; nomeJogador[0] = '\0'; tamanhoNome = 0; estadoAtual = ESTADO_SALVAR_RECORDE; return; } }
    if (estadoAtual == ESTADO_SALVAR_RECORDE) { if (!salvoComSucesso) { if (tecla == 13 && tamanhoNome > 0) { FILE* arquivo = fopen("ranking.txt", "a"); if (arquivo) { fprintf(arquivo, "Conde: %-10s | Destino: %-22s | HP: %3d%%\n", nomeJogador, causaMorteAtual, (int)conde.energia_vital); fclose(arquivo); salvoComSucesso = true; } } else if (tecla == 8 || tecla == 127) { if (tamanhoNome > 0) { tamanhoNome--; nomeJogador[tamanhoNome] = '\0'; } } else if (tecla >= 32 && tecla <= 126 && tamanhoNome < 12) { nomeJogador[tamanhoNome] = tecla; tamanhoNome++; nomeJogador[tamanhoNome] = '\0'; } if (tecla == 27) estadoAtual = ESTADO_MENU; } else { estadoAtual = ESTADO_MENU; } return; }

    if (estadoAtual == ESTADO_VITORIA && (tecla == 'c' || tecla == 'C')) { if (faseAtualRoteada == ESTADO_FASE2) { resetarJogo(); estadoAtual = ESTADO_FASE2; return; } }
    if (estadoAtual == ESTADO_GAME_OVER || estadoAtual == ESTADO_VITORIA) { if (tecla == 'r' || tecla == 'R') { resetarJogo(); estadoAtual = faseAtualRoteada; } if (tecla == 'm' || tecla == 'M') estadoAtual = ESTADO_MENU; if (tecla == 's' || tecla == 'S') { salvoComSucesso = false; nomeJogador[0] = '\0'; tamanhoNome = 0; estadoAtual = ESTADO_SALVAR_RECORDE; } } else if (estadoAtual == ESTADO_HISTORICO && (tecla == 'm' || tecla == 'M')) estadoAtual = ESTADO_MENU;
}

void renderizarCena() { switch (estadoAtual) { case ESTADO_MENU: desenharMenu(); break; case ESTADO_FASE1: desenharFase1(); break; case ESTADO_FASE2: desenharFase2(); break; case ESTADO_PAUSE: desenharPause(); break; case ESTADO_SALVAR_RECORDE: desenharSalvarRecorde(); break; case ESTADO_HISTORICO: desenharHistorico(); break; case ESTADO_GAME_OVER: desenharTelasFinais(causaMorteAtual, "Pressione [R] para reiniciar ou [M] para o Menu"); break; case ESTADO_VITORIA: desenharTelasFinais(causaMorteAtual, "Pressione [R] para repassar ou [M] para o Menu"); break; } glutSwapBuffers(); }

int main(int argc, char** argv) { glutInit(&argc, argv); glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB); glutInitWindowSize(TELA_LARGURA, TELA_ALTURA); glutCreateWindow("Corre Conde - Vertical Slice (Base Sanitizada)"); glMatrixMode(GL_PROJECTION); glLoadIdentity(); glOrtho(0.0, TELA_LARGURA, 0.0, TELA_ALTURA, -1.0, 1.0); glMatrixMode(GL_MODELVIEW); glutDisplayFunc(renderizarCena); glutTimerFunc(16, atualizarFisica, 0); glutMouseFunc(gerenciarMouse); glutSpecialFunc(pressionarTeclasEspeciais); glutSpecialUpFunc(soltarTeclas); glutKeyboardFunc(tecladoNormal); glutMainLoop(); return 0; }