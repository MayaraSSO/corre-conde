#include <GL/freeglut.h>
#include <stdbool.h>
#include <stdio.h>

// --- CONFIGURAÇÕES DA PROJEÇÃO E JANELA ---
#define NUM_PLATAFORMAS 4
#define TELA_LARGURA 800
#define TELA_ALTURA 600

// --- ESTRUTURAS DE DADOS (ENTIDADES ESPACIAIS) ---
typedef struct {
    float x, y;
    float largura, altura; // Dimensões para o Volume Envolvente (AABB)
    float velX, velY;      // Vetores de transformação (Translação)
    float velocidade;      // Passo de translação horizontal
    bool noChao;           // Flag de estado geométrico
} Jogador;

typedef struct {
    float x, y, largura, altura; // Dimensões dos polígonos estáticos
} Plataforma;

// --- VARIÁVEIS GLOBAIS DE ESTADO ---
Jogador conde = {100.0f, 300.0f, 30.0f, 50.0f, 0.0f, 0.0f, 5.0f, false};

// Variável para animação do efeito Parallax (Névoa)
float deslocamentoNevoa = 0.0f;

// Instanciamento dos volumes do cenário
Plataforma cenario[NUM_PLATAFORMAS] = {
    {0.0f, 50.0f, 400.0f, 40.0f},    // Chão inicial
    {500.0f, 50.0f, 300.0f, 40.0f},  // Chão após o primeiro buraco
    {950.0f, 150.0f, 150.0f, 20.0f}, // Plataforma flutuante 1
    {1200.0f, 250.0f, 200.0f, 20.0f} // Plataforma flutuante 2
};

// Constantes de translação
const float GRAVIDADE = -0.5f;   // Decaimento contínuo no eixo Y
const float FORCA_PULO = 12.0f;  // Impulso de translação positiva no eixo Y

// Estados de captura do teclado
bool teclaEsquerda = false;
bool teclaDireita = false;

// --- TESTES DE INTERSECÇÃO GEOMÉTRICA (AABB) ---

// Função de validação de sobreposição de volumes envolventes bidimensionais
bool verificaColisao(float ax, float ay, float aw, float ah, float bx, float by, float bw, float bh) {
    return (ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by);
}

// Previsão de colisão: verifica se a transformação pretendida violará o espaço do cenário
bool podeMoverPara(float proxX, float proxY) {
    for (int i = 0; i < NUM_PLATAFORMAS; i++) {
        if (verificaColisao(proxX, proxY, conde.largura, conde.altura, 
                            cenario[i].x, cenario[i].y, cenario[i].largura, cenario[i].altura)) {
            return false; // Intersecção detectada, bloqueia a translação
        }
    }
    return true; // Espaço livre para renderização
}

// --- PIPELINE DE ATUALIZAÇÃO ESPACIAL ---

void atualizarFisica(int value) {
    // 1. Translação Horizontal e validação de limite (Evita clipping nas paredes)
    float proxX = conde.x;
    if (teclaEsquerda) proxX -= conde.velocidade;
    if (teclaDireita) proxX += conde.velocidade;

    if (podeMoverPara(proxX, conde.y)) {
        conde.x = proxX; // Aplica a transformação
    }

    // 2. Translação Vertical (Simulação de salto e queda)
    conde.velY += GRAVIDADE;
    float proxY = conde.y + conde.velY;
    
    conde.noChao = false;

    // 3. Resolução de Intersecções no Eixo Y
    for (int i = 0; i < NUM_PLATAFORMAS; i++) {
        // Valida se o vetor descendente colide com o topo de um polígono
        if (conde.velY <= 0 && verificaColisao(conde.x, proxY, conde.largura, conde.altura, 
                                              cenario[i].x, cenario[i].y, cenario[i].largura, cenario[i].altura)) {
            // Corrige a coordenada para evitar o trespasse (clipping)
            proxY = cenario[i].y + cenario[i].altura;
            conde.velY = 0.0f;
            conde.noChao = true;
        }
    }
    conde.y = proxY;

    // 4. Tratamento de violação do limite inferior (Respawn)
    if (conde.y < -100.0f) {
        conde.x = 100.0f;
        conde.y = 300.0f;
        conde.velY = 0.0f;
    }
    
    // 5. Atualização da variável de Parallax (Efeito Névoa)
    deslocamentoNevoa += 0.5f; 
    if (deslocamentoNevoa > 800.0f) deslocamentoNevoa = 0.0f;
    
    glutPostRedisplay(); // Solicita nova rasterização
    glutTimerFunc(16, atualizarFisica, 0); // Mantém o loop travado a ~60 FPS
}

// --- CAPTURA DE EVENTOS ---

void tecladoEspecial(int key, int x, int y) {
    if (key == GLUT_KEY_RIGHT) teclaDireita = true;
    if (key == GLUT_KEY_LEFT) teclaEsquerda = true;
    if (key == GLUT_KEY_UP && conde.noChao) {
        conde.velY = FORCA_PULO; // Aplica o impulso de translação no eixo Y
        conde.noChao = false;
    }
}

void tecladoEspecialSolto(int key, int x, int y) {
    if (key == GLUT_KEY_RIGHT) teclaDireita = false;
    if (key == GLUT_KEY_LEFT) teclaEsquerda = false;
}

// --- EFEITOS VISUAIS E BLENDING ---

void desenharNevoaFria() {
    // Ativa interpolação de opacidade (Alpha Blending)
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Renderiza camadas de névoa com gradiente linear para suavizar bordas
    for (int i = 0; i < 4; i++) {
        float yBase = i * 100.0f; 
        
        // Multiplicador de Parallax (camadas em velocidades distintas)
        float velocidadeFaixa = deslocamentoNevoa * (1.0f + (i * 0.2f)); 
        
        // Polígono inferior (Transição transparente -> cinza)
        glBegin(GL_QUADS);
            glColor4f(0.5f, 0.6f, 0.7f, 0.0f); // Alpha 0.0 (Invisível)
            glVertex2f(-1000.0f + velocidadeFaixa, yBase);
            glVertex2f(3000.0f + velocidadeFaixa, yBase);

            glColor4f(0.4f, 0.5f, 0.6f, 0.15f); // Alpha 0.15 (Visível)
            glVertex2f(3000.0f + velocidadeFaixa, yBase + 75.0f);
            glVertex2f(-1000.0f + velocidadeFaixa, yBase + 75.0f);
        glEnd();

        // Polígono superior (Transição cinza -> transparente)
        glBegin(GL_QUADS);
            glColor4f(0.4f, 0.5f, 0.6f, 0.15f);
            glVertex2f(-1000.0f + velocidadeFaixa, yBase + 75.0f);
            glVertex2f(3000.0f + velocidadeFaixa, yBase + 75.0f);

            glColor4f(0.5f, 0.6f, 0.7f, 0.0f);
            glVertex2f(3000.0f + velocidadeFaixa, yBase + 150.0f);
            glVertex2f(-1000.0f + velocidadeFaixa, yBase + 150.0f);
        glEnd();
    }

    glDisable(GL_BLEND);
}

// --- RASTERIZAÇÃO DA CENA ---

void desenharCena() {
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0.1f, 0.1f, 0.15f, 1.0f); // Limpeza do buffer com cor noturna

    glPushMatrix();
    
    // SISTEMA DE CÂMERA: Translação inversa da matriz de modelagem
    glTranslatef(-conde.x + (TELA_LARGURA / 2), 0.0f, 0.0f);

    // Renderização dos polígonos estáticos (Cenário)
    glColor3f(0.4f, 0.4f, 0.4f); 
    for (int i = 0; i < NUM_PLATAFORMAS; i++) {
        glBegin(GL_QUADS);
            glVertex2f(cenario[i].x, cenario[i].y);
            glVertex2f(cenario[i].x + cenario[i].largura, cenario[i].y);
            glVertex2f(cenario[i].x + cenario[i].largura, cenario[i].y + cenario[i].altura);
            glVertex2f(cenario[i].x, cenario[i].y + cenario[i].altura);
        glEnd();
    }

    // Renderização do protagonista
    glColor3f(0.8f, 0.1f, 0.1f); 
    glBegin(GL_QUADS);
        glVertex2f(conde.x, conde.y);
        glVertex2f(conde.x + conde.largura, conde.y);
        glVertex2f(conde.x + conde.largura, conde.y + conde.altura);
        glVertex2f(conde.x, conde.y + conde.altura);
    glEnd();
    
    desenharNevoaFria();
    
    glPopMatrix();
    glutSwapBuffers(); // Efetua a troca de buffers (Double Buffering)
}

// --- INICIALIZAÇÃO DO CONTEXTO OPENGL ---

int main(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
    glutInitWindowSize(TELA_LARGURA, TELA_ALTURA);
    glutCreateWindow("Fuga do Conde - Prototipo Entrega 1");

    // Configuração da Projeção Ortogonal (World Space)
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(0, TELA_LARGURA, 0, TELA_ALTURA);
    glMatrixMode(GL_MODELVIEW);

    glutDisplayFunc(desenharCena);
    
    // Mapeamento de periféricos
    glutSpecialFunc(tecladoEspecial);
    glutSpecialUpFunc(tecladoEspecialSolto);

    // Inicia o motor de transformações espaciais
    glutTimerFunc(16, atualizarFisica, 0);

    glutMainLoop();
    return 0;
}