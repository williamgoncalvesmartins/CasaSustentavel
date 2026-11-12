# Casa Sustentável

Abra project.godot no Godot 4.7 e execute com F5.

O jogo tem três desafios de comparação na fase 1 e um caça-palavras na fase 2. Progresso e relatórios permanecem em user://progresso.json e user://relatorio.json.

## Narração neural offline

A narração usa Francisca Neural (pt-BR), voz feminina brasileira da Microsoft, com velocidade 8% mais lenta e tom original. As falas estão em audio/francisca e são reproduzidas diretamente pelo Godot, sem internet, PowerShell, voz instalada ou espera de geração durante a partida. Os áudios antigos da Maria não são consultados.

Menus, botões, instruções, mensagens e créditos usam gravações de frases inteiras. Resultados variáveis combinam trechos e números com a mesma voz. Nomes que não constam das gravações são soletrados localmente. Nenhum nome ou resultado de aluno é enviado para geração de áudio.

Passe o ponteiro por um instante sobre um botão, objeto ou texto para ouvir. O foco do teclado também lê botões. Sair interrompe a voz e fecha imediatamente.

## Atualizar falas

tools/voice_texts.json contém o catálogo. tools/generate_voice.py gera os MP3, manifest.json e voice_bank.gd usando edge-tts 7.3.1. A geração requer internet e Python com edge-tts; a execução do jogo não requer nenhum deles. voice_bank.gd referencia os MP3 por preload, incluindo-os na exportação.

Referências:
- https://learn.microsoft.com/pt-br/azure/ai-services/speech-service/language-support
- https://github.com/rany2/edge-tts

## Manutenção

LIMPEZA.md contém o registro da limpeza anterior. Os scripts check_*.gd são verificações de desenvolvimento.
