import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void registerWebView(String viewId, String url) {
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) {
      final iframe = html.IFrameElement();
      iframe.src = url;
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      return iframe;
    },
  );
}
