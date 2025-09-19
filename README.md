# NA Posters App

Aplicativo Flutter offline-first projetado para ajudar voluntários de Narcóticos Anônimos (NA) a planejar, fixar e manter cartazes nas comunidades. O app sugere locais ideais de colagem ao redor de grupos de NA (ex.: “Só por Hoje – Barroca, BH”), evitando bares e priorizando pontos úteis como farmácias, postos de saúde, supermercados e praças. Também permite registrar manutenções de cartazes e exportar dados para relatórios.

## Visão

Nossa missão é divulgar as reuniões de NA colocando cartazes em locais significativos, respeitando as normas da comunidade. Este app ajuda voluntários a maximizar o alcance e minimizar o esforço usando dados abertos e heurísticas inteligentes para sugerir os melhores pontos.

## Funcionalidades Principais

- **Seleção de Grupo & Área** – escolha um grupo de NA, raio em quilômetros e número de cartazes para gerar sugestões.
- **Recomendações Inteligentes** – pontua os pontos de interesse (POIs) com base em distância, densidade e categoria, priorizando farmácias, postos de saúde, mercados e praças e evitando bares.
- **Visualização no Mapa** – veja no mapa os POIs candidatos, alterne camadas de “bons” e “evitar” e salve novos pontos de colagem.
- **Dados Offline** – usa banco de dados SQLite local (`sqflite`) para que mapas e registros funcionem sem internet.
- **Registros de Manutenção** – para cada ponto de cartaz, registre status, notas, fotos e assinatura do responsável.
- **Histórico & Status** – acompanhe o histórico de manutenções, filtre por status e veja quais cartazes precisam de atenção.
- **Exportar & Importar** – exporte todos os dados como um ZIP (GeoJSON + fotos/assinaturas) e importe de volta se necessário.
- **Roteirização** – planeje uma rota ótima para cobrir vários pontos de cartazes.

## Melhorias Futuras

Nosso backlog evolui constantemente. Algumas ideias para o futuro:

- Integração com dados de trânsito em tempo real para melhorar roteirização.
- Autenticação com contas de serviço do NA para sincronizar dados entre dispositivos.
- Um pequeno portal web para coordenadores monitorarem vários grupos.
- Notificações push quando cartazes estiverem perto do vencimento da manutenção.
- Modo escuro e melhorias de acessibilidade.

## Começando

1. **Clone o repositório**

   ```bash
   git clone https://github.com/fayzerlol/NA-Posters-App.git
   cd NA-Posters-App
   ```

2. **Instale as dependências do Flutter**

   Certifique-se de ter o Flutter (canal estável) instalado. Em seguida execute:

   ```bash
   flutter pub get
   ```

3. **Execute o aplicativo**

   ```bash
   flutter run
   ```

   O app funciona offline por padrão. Se desejar baixar POIs atualizados, esteja conectado à internet.

## Estrutura do Projeto

```
lib/             # UI Flutter, páginas e widgets
  models/        # Modelos de dados para grupos, POIs, cartazes, manutenções
  services/      # Serviços de banco de dados e API (Overpass/OSM, exportação/importação)
  ui/            # Widgets de apresentação (formulários, listas, modais)
  screens/       # Telas de alto nível (HomeScreen, MapScreen, HistoryScreen)
  utils/         # Funções auxiliares e constantes
assets/
  images/        # Ícones e logos de exemplo
  data/          # Dados de POI offline empacotados (opcional)
scripts/         # Scripts shell para automação do projeto (rótulos, milestones, issues)
.github/
  workflows/     # Configuração do GitHub Actions (CI)
  ISSUE_TEMPLATE/ # Modelos de issues para funcionalidades e bugs
```

## Contribuindo

Contribuições da comunidade NA são bem-vindas! Para colaborar:

1. **Abra uma issue** – use os modelos para relatar bugs ou solicitar funcionalidades.
2. **Trabalhe em uma issue** – comente em uma issue aberta para indicar que você está trabalhando nela.
3. **Abra um pull request** – faça um fork do repositório, crie uma branch com suas mudanças e envie um PR. Siga o modelo de pull request para descrever o que foi feito e como testar.
4. **Estilo de código** – execute `flutter format` e `flutter analyze` antes de commitar.

## Roteiro (Roadmap)

Consulte o Project e os milestones para ver as funcionalidades planejadas. No momento:

- **MVP 0.1 – Mapa + Offline** (até 05 de outubro de 2025): visualização do mapa, banco local e navegação básica.
- **0.2 – Recomendção & POIs** (até 20 de outubro de 2025): algoritmo de pontuação, integração com POIs, sugestões top‑K.
- **0.3 – Manutenção & Exportar** (até 05 de novembro de 2025): registro de manutenção, exportação/importação de dados.

## Licença

[MIT](LICENSE)

---

Só por hoje! Obrigado por apoiar nossa irmandade e ajudar a levar a mensagem de NA a quem ainda sofre.
