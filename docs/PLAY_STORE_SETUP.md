# Configuração do paywall na Google Play

O app usa uma compra única não consumível para liberar todos os ritmos.

## Produto

- ID: `super_cajon_full_unlock`
- Tipo: produto único / não consumível
- Benefício: acesso permanente aos 13 ritmos

O ID precisa ser exatamente igual ao valor definido em
`PurchaseService.fullUnlockId`.

## Play Console

1. Crie o aplicativo no Google Play Console com o package name
   `com.matheusfonseca.super_cajon`.
2. Gere e envie um Android App Bundle para uma faixa de teste interno:
   `flutter build appbundle --release`.
3. Em **Monetização > Produtos únicos**, crie o produto
   `super_cajon_full_unlock`.
4. Defina nome, descrição e preço e ative o produto.
5. Adicione as contas de teste em **Configurações > Teste de licença**.
6. Instale o app pelo link da faixa de teste. Compras não ficam disponíveis
   em APKs instalados diretamente nem no preview Chrome.

## Ritmos gratuitos

- Arrocha
- Pagode
- Xote

Os outros dez ritmos abrem o paywall. A tela de ajustes também oferece acesso
ao paywall e à restauração da compra.

## Antes da produção

A implementação mantém o desbloqueio local para funcionamento offline. Antes
do lançamento público, é recomendado validar o token da compra em um backend
usando a Google Play Developer API para reduzir fraude.
