# Publicação e conformidade na Google Play

O Super Cajon usa uma assinatura anual autorrenovável para liberar o catálogo
premium e os novos packs de loops publicados trimestralmente.

## Assinatura

- Produto: `super_cajon_pro`
- Plano-base: `anual`
- Período: 1 ano, autorrenovável
- Preço-base no Brasil: R$ 29,99 por ano
- Benefícios: catálogo premium e novos packs trimestrais

O ID precisa ser exatamente igual a
`PurchaseService.annualSubscriptionId`. O preço mostrado no app vem dos
`ProductDetails` da Google Play; o valor fixo é usado apenas no preview de
marketing.

## Configuração no Play Console

1. Crie o app com o package name `supercajon.app`.
2. Habilite Play App Signing e cadastre a upload key de produção.
3. Em **Monetização > Assinaturas**, crie `super_cajon_pro`.
4. Crie o plano-base `anual`, autorrenovável, com período de 1 ano.
5. Configure R$ 29,99 no Brasil e revise os preços convertidos em outros países.
6. Configure período de carência e suspensão de conta conforme os requisitos
   vigentes da Google Play (a soma deve ser de pelo menos 30 dias quando essa
   regra for aplicável).
7. Ative a assinatura e publique um AAB em teste interno.
8. Adicione as contas de teste em **Configurações > Teste de licença**.
9. Teste compra, cancelamento, renovação acelerada, falha de pagamento,
   restauração, expiração, reembolso e reinstalação.

## Conteúdo gratuito e recorrente

- Gratuitos: Arrocha, Pagode e Xote.
- Premium: demais ritmos e packs trimestrais.

Mantenha evidência interna de cada entrega trimestral. A política de assinaturas
exige valor sustentado ou recorrente durante toda a assinatura; não publique o
plano anual se o calendário de novos conteúdos for abandonado.

## App content e página da loja

Antes da produção, conclua no Play Console:

- Política de privacidade: URL HTTPS pública, ativa, não geobloqueada e não PDF.
- Segurança dos dados: sem coleta/compartilhamento, enquanto não existir backend
  nem outro SDK que transmita dados do usuário para fora do dispositivo.
- Anúncios: declarar que o app não contém anúncios.
- Acesso ao app: nenhuma credencial é necessária; os revisores podem usar os
  ritmos gratuitos e o fluxo de assinatura da faixa de teste.
- Público-alvo e classificação etária: preencher de forma consistente com
  `LegalConfig.minimumTargetAge`.
- Compras no app: informar que o catálogo premium exige assinatura anual.
- Conteúdo: concluir o questionário de classificação com respostas verdadeiras.
- E-mail de suporte e dados públicos do desenvolvedor: manter válidos.

A descrição e as capturas devem deixar claro que há três ritmos gratuitos e que
o restante depende da assinatura anual. Não use "totalmente offline": a
assinatura exige validação periódica.

## Política de privacidade e termos

Os arquivos prontos para publicação estão em:

- `docs/privacy-policy.html`
- `docs/terms-of-use.html`

Substitua todos os valores `PENDENTE_`, publique as páginas em HTTPS (por
exemplo, GitHub Pages) e atualize `lib/config/legal_config.dart` com as URLs
finais. O build release falha intencionalmente enquanto existirem pendências.

## Assinatura do AAB

1. Gere uma upload key e guarde-a fora do Git.
2. Copie `android/key.properties.example` para `android/key.properties`.
3. Preencha o caminho e as senhas da chave.
4. Gere o bundle com `flutter build appbundle --release`.

Nunca envie `key.properties` ou o arquivo `.jks` ao repositório.

## Validação da assinatura

O app consulta assinaturas ativas na Google Play ao iniciar, ao voltar ao
primeiro plano, a cada seis horas e quando o usuário solicita restauração. O
acesso offline é mantido por até três dias desde a última validação bem-sucedida.

Para proteção mais forte contra fraude e para reagir imediatamente a
renovações, reembolsos e revogações, adicione um backend com Google Play
Developer API e Real-time Developer Notifications. Ao fazer isso, atualize a
política de privacidade e o formulário Segurança dos dados para declarar os
dados transmitidos.

## Direitos e suporte

Antes de publicar, preserve documentos que comprovem a autoria ou licença
comercial dos áudios, capas, logo e demais recursos. Para produtos pagos, o DDA
exige suporte em até três dias úteis e em até 24 horas para solicitações que a
Google marcar como urgentes.

## Dados do titular no Play Console

Para uma conta pessoal, tenha em mãos nome civil, endereço físico, e-mail e
telefone verificáveis, nome público de desenvolvedor e site. Para uma
organização, também podem ser exigidos dados da empresa e D-U-N-S. Como o app é
monetizado, o endereço completo do perfil de pagamentos pode ser exibido
publicamente na Google Play.

O perfil de pagamentos brasileiro exige dados fiscais e bancários, como
CPF/CNPJ, titular, banco, agência e conta. Informe esses dados somente nas telas
oficiais da Google; não os grave no repositório, em arquivos do app ou em chats.
