import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void openInNewTab(String url) =>
    globalContext.callMethod('open'.toJS, url.toJS, '_blank'.toJS, 'noopener'.toJS);

String swiggySearchUrl(String dish) => 'https://www.swiggy.com/search?query=${Uri.encodeComponent(dish)}';

String mapsSearchUrl(String place) =>
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}';
