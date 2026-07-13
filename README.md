# Super Cajon

Aplicativo Flutter mobile e offline para reprodução de loops profissionais de cajón em apresentações ao vivo.

## Plataformas

- Android
- iOS
- Web

## Executar

```bash
flutter pub get
flutter run
```

Para escolher um dispositivo específico:

```bash
flutter devices
flutter run -d <device-id>
```

## Validar

```bash
flutter analyze
flutter test
flutter build web
```

## Estrutura principal

- `lib/main.dart`: interface, navegação e player.
- `assets/audio`: 13 loops WAV originais.
- `assets/covers`: capas dos ritmos.
- `assets/brand`: logo do aplicativo.
- `android`: projeto nativo Android.
- `ios`: projeto nativo iOS.

O player usa `just_audio`, reprodução contínua, ajuste de BPM, volume, troca de ritmo e parada suave. Os arquivos HTML/CSS/JavaScript na raiz e a pasta `SuperCajon` pertencem às versões anteriores e permanecem apenas como referência.

## Monetização Android

O aplicativo oferece Arrocha, Pagode e Xote gratuitamente. Os demais ritmos
são liberados pela compra única `super_cajon_full_unlock`, usando Google Play
Billing. A configuração necessária no Play Console está descrita em
`docs/PLAY_STORE_SETUP.md`.

### Testar a jornada do cliente sem cobrança

```bash
flutter run -d chrome --dart-define=CUSTOMER_PREVIEW=true
```

Nesse modo, tocar em qualquer ritmo bloqueado abre o paywall com o preço de
R$ 29,99. O botão de compra simula o desbloqueio, sem acessar a Google Play. Nos
ajustes, use **Resetar demonstração do paywall** para repetir o fluxo. Essa
simulação só é ativada quando a flag acima é informada e não afeta o build de
produção.
