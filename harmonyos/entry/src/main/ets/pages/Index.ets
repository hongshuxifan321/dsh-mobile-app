import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
  @State url: string = 'https://your-domain.de5.net/mobile';
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ src: this.url, controller: this.controller })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
